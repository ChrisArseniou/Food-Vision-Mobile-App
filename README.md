# FoodVision

FoodVision is a Flutter mobile app that analyzes pictures of food and provides estimated nutritional information such as calories, protein, carbs, and fats. It connects to an external Python backend powered by Google Gemini AI for image analysis.

We can either take a picture from our phone, or find a picture from our collection.
![1](https://github.com/user-attachments/assets/ddbca113-6d45-425f-bb9b-6f89132bbe86)

Clicking analyze the app interacts with the backend and with GEMINI.
![2](https://github.com/user-attachments/assets/ce6d2470-76d5-487d-a867-746d184cceb1)

After that, we get our results, that include a review of our food, calories, and nutrition breakdown of our food.
![3](https://github.com/user-attachments/assets/11bb6c84-b255-4141-8b95-8494adba9ef0)
![4](https://github.com/user-attachments/assets/75aa528e-0458-4311-8876-82b403b68e24)
![5](https://github.com/user-attachments/assets/23b69081-fe34-436d-8a51-467ce6f76f65)

## Features

- Capture or upload photos of meals  
- AI-based food recognition and nutrition estimation  
- Clean and responsive Flutter interface  
- Connects to a remote Python backend for processing  

## How It Works

1. The user uploads or takes a photo of their food.  
2. The image is sent to a Python backend (not included in this repository).  
3. The backend uses Google Gemini to analyze the food and estimate nutrition facts.  
4. The results are displayed in the app in a simple, easy-to-read format.

## Tech Stack

- **Flutter** – Frontend mobile application  
- **Python (external backend)** – Handles AI image analysis via Gemini  
- **Gemini API** – Provides food recognition and nutrition estimation

## License

This project is licensed under the MIT License.

## Setup

```bash
git clone https://github.com/yourusername/foodvision.git
cd foodvision
flutter pub get
flutter run 

