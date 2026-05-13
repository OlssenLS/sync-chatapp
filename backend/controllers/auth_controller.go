package controllers

import (
	"net/http"

	"github.com/OlssenLS/sync-chatapp/backend/models"
	"github.com/OlssenLS/sync-chatapp/backend/utils"
	"github.com/gin-gonic/gin"
)

type RegisterInput struct {
	Email    string `json:"email" binding:"required,email"`
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required,min=6"`
}

type LoginInput struct {
	Identifier string `json:"identifier" binding:"required"` // Username or Email
	Password   string `json:"password" binding:"required"`
}

func Register(c *gin.Context) {
	var input RegisterInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Please provide valid registration details"})
		return
	}

	// Manual secondary validation
	if len(input.Password) < 8 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Password must be at least 8 characters long"})
		return
	}

	// Check if user already exists
	existingUser, _ := models.GetUserByUsernameOrEmail(input.Username)
	if existingUser != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Username is already taken"})
		return
	}

	existingEmail, _ := models.GetUserByUsernameOrEmail(input.Email)
	if existingEmail != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Email is already registered"})
		return
	}

	user := models.User{
		Email:    input.Email,
		Username: input.Username,
	}

	if err := user.HashPassword(input.Password); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
		return
	}

	if err := models.CreateUser(&user); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Registration successful"})
}

func Login(c *gin.Context) {
	var input LoginInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, err := models.GetUserByUsernameOrEmail(input.Identifier)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	if !user.CheckPassword(input.Password) {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	token, err := utils.GenerateToken(user.ID.Hex(), user.Username)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"token": token,
		"user":  user,
	})
}
