package utils

import (
	"encoding/json"
	"log"
	"sync"

	"github.com/gorilla/websocket"
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
	defer h.mu.Unlock()

	client, ok := h.Clients[userID]
	if !ok {
		log.Printf("User %s not connected", userID)
		return
	}

	payload, err := json.Marshal(message)
	if err != nil {
		log.Printf("Error marshalling message: %v", err)
		return
	}

	select {
	case client.Send <- payload:
	default:
		log.Printf("Send channel full for user %s", userID)
	}
}
