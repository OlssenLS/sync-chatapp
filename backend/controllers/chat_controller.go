package controllers

import (
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/OlssenLS/sync-chatapp/backend/models"
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

func (cc *ChatController) GetHistory(c *gin.Context) {
	senderID := c.Query("sender_id")
	receiverID := c.Query("receiver_id")
	limitStr := c.DefaultQuery("limit", "50")

	if senderID == "" || receiverID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "sender_id and receiver_id are required"})
		return
	}

	limit, err := strconv.ParseInt(limitStr, 10, 64)
	if err != nil {
		limit = 50
	}

	messages, err := models.GetChatHistory(senderID, receiverID, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch history"})
		return
	}

	c.JSON(http.StatusOK, messages)
}

func (cc *ChatController) GetConversations(c *gin.Context) {
	userID := c.Query("user_id")
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "user_id is required"})
		return
	}

	conversations, err := models.GetActiveConversations(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch conversations"})
		return
	}

	c.JSON(http.StatusOK, conversations)
}

func (cc *ChatController) MarkAsRead(c *gin.Context) {
	var body struct {
		SenderID   string `json:"sender_id"`
		ReceiverID string `json:"receiver_id"`
	}

	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	if err := models.MarkMessagesAsRead(body.SenderID, body.ReceiverID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to mark as read"})
		return
	}

	// Notify the sender that their messages were read (via WS if online)
	cc.Hub.SendToUser(body.SenderID, utils.WSMessage{
		Type:       "read",
		SenderID:   body.ReceiverID, // User who read the messages
		ReceiverID: body.SenderID,
		Timestamp:  time.Now(),
	})

	c.JSON(http.StatusOK, gin.H{"status": "success"})
}

func (cc *ChatController) UpdateFCMToken(c *gin.Context) {
	var body struct {
		UserID string `json:"user_id"`
		Token  string `json:"token"`
	}

	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	if err := models.UpdateFCMToken(body.UserID, body.Token); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "success"})
}

// Separate pumps logic for Client (usually in utils or a separate file)
// For simplicity, we add helper methods here or in utils
