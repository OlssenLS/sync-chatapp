package controllers

import (
	"log"
	"net/http"

	"github.com/OlssenLS/sync-chatapp/backend/utils"
	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // In production, check against whitelist
	},
}

type ChatController struct {
	Hub *utils.Hub
}

func NewChatController(hub *utils.Hub) *ChatController {
	return &ChatController{Hub: hub}
}

func (cc *ChatController) HandleWebSocket(c *gin.Context) {
	userID := c.Query("user_id") // Should be extracted from JWT in production
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "user_id is required"})
		return
	}

	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("Failed to upgrade to WebSocket: %v", err)
		return
	}

	client := &utils.Client{
		UserID: userID,
		Conn:   conn,
		Send:   make(chan []byte, 256),
	}

	cc.Hub.Register <- client

	// Start read/write pumps
	go client.WritePump()
	go client.ReadPump(cc.Hub)
}

// Separate pumps logic for Client (usually in utils or a separate file)
// For simplicity, we add helper methods here or in utils
