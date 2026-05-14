package routes

import (
	"github.com/OlssenLS/sync-chatapp/backend/controllers"
	"github.com/OlssenLS/sync-chatapp/backend/utils"
	"github.com/gin-gonic/gin"
)

func RegisterChatRoutes(r *gin.Engine, hub *utils.Hub) {
	chatController := controllers.NewChatController(hub)

	chat := r.Group("/chat")
	{
		chat.GET("/ws", chatController.HandleWebSocket)
	}
}
