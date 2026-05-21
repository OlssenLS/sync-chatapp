package utils

import (
	"encoding/json"
	"log"
	"sync"

	"github.com/OlssenLS/sync-chatapp/backend/db"
	"github.com/gorilla/websocket"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

// Client represents a connected user
type Client struct {
	UserID string
	Conn   *websocket.Conn
	Send   chan []byte
}

// Hub maintains the set of active clients
type Hub struct {
	Clients    map[string]*Client
	Register   chan *Client
	Unregister chan *Client
	Broadcast  chan []byte // Not used for private chat, but good for announcements
	mu         sync.Mutex
}

func NewHub() *Hub {
	return &Hub{
		Clients:    make(map[string]*Client),
		Register:   make(chan *Client),
		Unregister: make(chan *Client),
		Broadcast:  make(chan []byte),
	}
}

func (h *Hub) Run() {
	for {
		select {
		case client := <-h.Register:
			h.mu.Lock()
			h.Clients[client.UserID] = client
			h.mu.Unlock()
			log.Printf("User %s connected", client.UserID)

		case client := <-h.Unregister:
			h.mu.Lock()
			if _, ok := h.Clients[client.UserID]; ok {
				delete(h.Clients, client.UserID)
				close(client.Send)
				log.Printf("User %s disconnected", client.UserID)
			}
			h.mu.Unlock()

		case message := <-h.Broadcast:
			h.mu.Lock()
			for _, client := range h.Clients {
				select {
				case client.Send <- message:
				default:
					close(client.Send)
					delete(h.Clients, client.UserID)
				}
			}
			h.mu.Unlock()
		}
	}
}

// SendToUser routes a message to a specific connected user
func (h *Hub) SendToUser(userID string, message interface{}) {
	h.mu.Lock()
	client, ok := h.Clients[userID]
	h.mu.Unlock()

	payload, err := json.Marshal(message)
	if err != nil {
		log.Printf("Error marshalling message: %v", err)
		return
	}

	if ok {
		select {
		case client.Send <- payload:
		default:
			log.Printf("Send channel full for user %s", userID)
		}
		return
	}

	// User not connected, send push notification if it's a chat message
	log.Printf("User %s not connected, attempting push notification", userID)

	wsMsg, isWsMsg := message.(WSMessage)
	if isWsMsg && wsMsg.Type == "chat" && GlobalNotificationService != nil {
		// Fetch recipient's FCM token from DB
		var user struct {
			FCMToken string `bson:"fcm_token"`
			Username string `bson:"username"`
		}
		collection := db.GetCollection("users")
		objID, _ := bson.ObjectIDFromHex(userID)
		err := collection.FindOne(nil, bson.M{"_id": objID}).Decode(&user)

		if err == nil && user.FCMToken != "" {
			// Also fetch sender's username for the notification title
			var sender struct {
				Username string `bson:"username"`
			}
			senderID, _ := bson.ObjectIDFromHex(wsMsg.SenderID)
			db.GetCollection("users").FindOne(nil, bson.M{"_id": senderID}).Decode(&sender)

			title := sender.Username
			if title == "" {
				title = "New Message"
			}

			body := "You have a new message"
			if content, ok := wsMsg.Content.(string); ok {
				body = content
			}

			data := map[string]string{
				"type":        "chat",
				"sender_id":   wsMsg.SenderID,
				"receiver_id": userID,
			}

			go GlobalNotificationService.SendPushNotification(user.FCMToken, title, body, data)
		} else if err != nil && err != mongo.ErrNoDocuments {
			log.Printf("Error fetching user for push: %v", err)
		}
	}
}
