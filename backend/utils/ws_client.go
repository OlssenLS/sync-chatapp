package utils

import (
	"encoding/json"
	"log"
	"time"

	"github.com/OlssenLS/sync-chatapp/backend/models"
	"github.com/gorilla/websocket"
)

const (
	writeWait      = 10 * time.Second
	pongWait       = 60 * time.Second
	pingPeriod     = (pongWait * 9) / 10
	maxMessageSize = 512
)

type WSMessage struct {
	Type       string      `json:"type"`
	SenderID   string      `json:"sender_id"`
	ReceiverID string      `json:"receiver_id"`
	Content    interface{} `json:"content"`
	Timestamp  time.Time   `json:"timestamp"`
}

func (c *Client) ReadPump(h *Hub) {
	defer func() {
		h.Unregister <- c
		c.Conn.Close()
	}()

	c.Conn.SetReadLimit(maxMessageSize)
	c.Conn.SetReadDeadline(time.Now().Add(pongWait))
	c.Conn.SetPongHandler(func(string) error {
		c.Conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})

	for {
		_, message, err := c.Conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("error: %v", err)
			}
			break
		}

		var wsMsg WSMessage
		if err := json.Unmarshal(message, &wsMsg); err != nil {
			log.Printf("error unmarshalling message: %v", err)
			continue
		}

		// Use the authenticated UserID from the client object
		wsMsg.SenderID = c.UserID
		wsMsg.Timestamp = time.Now()

		if wsMsg.Type == "chat" && wsMsg.ReceiverID != "" {
			log.Printf("Routing message from %s to %s", c.UserID, wsMsg.ReceiverID)

			// Persist message to MongoDB
			dbMsg := models.Message{
				SenderID:   c.UserID,
				ReceiverID: wsMsg.ReceiverID,
				Content:    wsMsg.Content.(string),
				Type:       "text",
				Timestamp:  wsMsg.Timestamp,
			}
			if err := models.SaveMessage(&dbMsg); err != nil {
				log.Printf("Failed to save message: %v", err)
			}

			// Deliver to recipient
			h.SendToUser(wsMsg.ReceiverID, wsMsg)

			// Echo back to sender for confirmation/UI update
			h.SendToUser(c.UserID, wsMsg)
		}
	}
}

func (c *Client) WritePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.Conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.Send:
			c.Conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				c.Conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			w, err := c.Conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			w.Write(message)

			// Add queued chat messages to the current websocket message
			n := len(c.Send)
			for i := 0; i < n; i++ {
				w.Write([]byte{'\n'})
				w.Write(<-c.Send)
			}

			if err := w.Close(); err != nil {
				return
			}
		case <-ticker.C:
			c.Conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}
