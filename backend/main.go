package main

import (
	"log"
	"net/http"
	"os"

	"github.com/OlssenLS/sync-chatapp/backend/db"
	"github.com/OlssenLS/sync-chatapp/backend/routes"
	"github.com/OlssenLS/sync-chatapp/backend/utils"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	// Load .env file
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using system environment variables")
	}

	// Initialize MongoDB
	db.ConnectDB()

	// Initialize WebSocket Hub
	hub := utils.NewHub()
	go hub.Run()

	// Initialize Gin router
	r := gin.Default()

	// Register Routes
	routes.RegisterAuthRoutes(r)
	routes.RegisterChatRoutes(r, hub)

	// Health check
	r.GET("/ping", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "pong"})
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Println("Server starting on :" + port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Failed to run server: %v", err)
	}
}
