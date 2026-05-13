package main

import (
	"log"
	"net/http"

	"github.com/OlssenLS/sync-chatapp/backend/db"
	"github.com/OlssenLS/sync-chatapp/backend/routes"
	"github.com/gin-gonic/gin"
)

func main() {
	// Initialize MongoDB
	db.ConnectDB()

	// Initialize Gin router
	r := gin.Default()

	// Register Routes
	routes.RegisterAuthRoutes(r)

	// Health check
	r.GET("/ping", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "pong"})
	})

	log.Println("Server starting on :8080")
	if err := r.Run(":8080"); err != nil {
		log.Fatalf("Failed to run server: %v", err)
	}
}
