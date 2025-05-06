const functions = require('firebase-functions');
const { GoogleGenerativeAI } = require('@google/generative-ai');

// Initialize Gemini API with the provided key
const genAI = new GoogleGenerativeAI('AIzaSyB7t7KatWmliVfyvtoj6BJJIZLLdYtHc-E');

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
    
    // Initialize the model
    const model = genAI.getGenerativeModel({ model: "gemini-pro" });
    
    // Create chat session
    const chat = model.startChat({
      history: chatHistory.map(msg => ({
        role: msg.role,
        parts: [{ text: msg.content }],
      })),
    });

    // Send message and get response
    const result = await chat.sendMessage(message);
    const response = await result.response;
    const text = response.text();

    return {
      response: text,
      timestamp: new Date().toISOString(),
    };
  } catch (error) {
    console.error('Error in chatWithGemini:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to process chat message',
      error.message
    );
  }
}); 