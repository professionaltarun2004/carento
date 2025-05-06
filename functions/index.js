const functions = require('firebase-functions');
const { GoogleGenerativeAI } = require('@google/generative-ai');

// Initialize Gemini API with the provided key
const GEMINI_API_KEY = 'AIzaSyB7t7KatWmliVfyvtoj6BJJIZLLdYtHc-E';

if (!GEMINI_API_KEY || GEMINI_API_KEY === 'YOUR_API_KEY') {
  throw new Error('Gemini API key is not configured. Please set a valid API key in the environment variables.');
}

const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);

exports.chatWithGemini = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to use chat'
    );
  }

  try {
    const { message, chatHistory } = data;
    
    if (!message || typeof message !== 'string' || message.trim().length === 0) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Message is required and must be a non-empty string'
      );
    }
    
    // Initialize the model
    const model = genAI.getGenerativeModel({ model: "gemini-pro" });
    
    // Create chat session
    const chat = model.startChat({
      history: chatHistory?.map(msg => ({
        role: msg.role,
        parts: [{ text: msg.content }],
      })) || [],
    });

    // Send message and get response
    const result = await chat.sendMessage(message);
    const response = await result.response;
    const text = response.text();

    if (!text) {
      throw new functions.https.HttpsError(
        'internal',
        'No response received from Gemini'
      );
    }

    return {
      response: text,
      timestamp: new Date().toISOString(),
    };
  } catch (error) {
    console.error('Error in chatWithGemini:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    if (error.message?.includes('API key')) {
      throw new functions.https.HttpsError(
        'internal',
        'Invalid API key configuration. Please check your configuration.'
      );
    }
    
    if (error.message?.includes('quota')) {
      throw new functions.https.HttpsError(
        'resource-exhausted',
        'API quota exceeded. Please try again later'
      );
    }
    
    if (error.message?.includes('network')) {
      throw new functions.https.HttpsError(
        'unavailable',
        'Network error. Please check your internet connection'
      );
    }
    
    if (error.message?.includes('timeout')) {
      throw new functions.https.HttpsError(
        'deadline-exceeded',
        'Request timed out. Please try again'
      );
    }
    
    throw new functions.https.HttpsError(
      'internal',
      'Failed to process chat message',
      error.message
    );
  }
}); 