const functions = require('firebase-functions');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp();

// Initialize Gemini
const apiKey = "AIzaSyB7t7KatWmliVfyvtoj6BJJIZLLdYtHc-E";
const genAI = new GoogleGenerativeAI(apiKey);

exports.chatWithGemini = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to use chat'
    );
  }

  const { message, chatId } = data;
  if (!message || !chatId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Message and chatId are required'
    );
  }

  try {
    // Get chat history
    const chatRef = admin.firestore().collection('chats');
    const chatSnapshot = await chatRef
      .where('chatId', '==', chatId)
      .orderBy('timestamp', 'asc')
      .get();

    // Build conversation history
    const history = chatSnapshot.docs.map(doc => {
      const data = doc.data();
      return {
        role: data.isUser ? 'user' : 'model',
        parts: [{ text: data.message }],
      };
    });

    // Initialize Gemini model
    const model = genAI.getGenerativeModel({ model: 'gemini-pro' });
    const chat = model.startChat({
      history: history,
      generationConfig: {
        maxOutputTokens: 1000,
        temperature: 0.7,
      },
    });

    // Get response from Gemini
    const result = await chat.sendMessage(message);
    const response = await result.response;
    const text = response.text();

    return { response: text };
  } catch (error) {
    console.error('Error in chatWithGemini:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Error processing chat message'
    );
  }
}); 