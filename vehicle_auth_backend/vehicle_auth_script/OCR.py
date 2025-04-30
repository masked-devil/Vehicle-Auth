import time
from selenium import webdriver
from selenium.webdriver.chrome.service import Service as ChromeService
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.by import By
import cv2
import webbrowser
import easyocr
import requests

def verify_vehicle(vehicle_number):
    url = f"https://3d38-103-241-82-18.ngrok-free.app/verify_vehicle?vehicle_number={vehicle_number}"
    
    try:
        response = requests.get(url)
        data = response.json()
        
        if data.get("exists"):
            print(f"Vehicle authorized. User ID: {data['user_id']}")
            return True  # Vehicle is authorized
        else:
            print("Vehicle not authorized.")
            return False  # Vehicle is not authorized

    except requests.exceptions.RequestException as e:
        print(f"Error connecting to the verification service: {e}")
        return False

class DemoFind():
    def locate(self):
        driver = webdriver.Chrome(service=ChromeService(ChromeDriverManager().install()))
        driver.get("http://172.16.6.100/")
        text = driver.find_element(By.XPATH, "/html/body/center/p").text
        return text

def equalizeHistColor(frame):
    img = cv2.cvtColor(frame, cv2.COLOR_RGB2HSV)
    img[:,:,2] = cv2.equalizeHist(img[:,:,2])
    return cv2.cvtColor(img, cv2.COLOR_HSV2RGB)

find = DemoFind()
while True:
    var = find.locate()
    if var == "Vehicle Detected":
        webcam = cv2.VideoCapture(0)
        if not webcam.isOpened():
            print("Error: Could not open camera.")
            exit()

        try:
            check, frame = webcam.read()
            cv2.imshow("Capturing", frame)
            cv2.waitKey(1)
            time.sleep(7) 
            cv2.imwrite(filename='saved_img.png', img=frame)
            webcam.release()
            img_new = cv2.imread('saved_img.png', cv2.IMREAD_GRAYSCALE)
            img = cv2.imread('saved_img.png')
            img = cv2.resize(img, (600, 360))
            cv2.imshow('Result', img_new)
            cv2.waitKey(1)
            img_new = equalizeHistColor(frame)
            img_new = cv2.imshow("Captured Image", img_new)
            cv2.waitKey(1)
            cv2.destroyAllWindows()
            print("Processing image...")
            img_ = cv2.imread('saved_img.png', cv2.IMREAD_ANYCOLOR)
            print("Converting RGB image to grayscale...")
            gray = cv2.cvtColor(img_, cv2.COLOR_BGR2GRAY)
            print("Converted RGB image to grayscale...")
            print("Resizing image to 256x256 scale...")
            img_ = cv2.resize(gray, (256,256))
            cv2.imwrite(filename='saved_img_final.png', img=img_)
            print("Image saved!")
            reader = easyocr.Reader(['en'])
            output = reader.readtext('saved_img_final.png')
            
            Allflag = "Vehicle not Authorized"
            
           
            print("DETECTED NUMBER PLATE:", "".join(output[0][1].upper().split()) if output else "No text detected")
            if output:
                vehicle_number = "".join(output[0][1].upper().split())  # Extracted plate number
                if verify_vehicle(vehicle_number):  # Check if vehicle is authorized
                    webbrowser.open("http://172.16.6.100/P")  # Open gate
                else:
                    print("Access Denied: Unauthorized vehicle.")
            else:
                print("No detection")

                
                
            flag = input("Do you want to flag this image? (y/n):")
            
            cv2.destroyAllWindows()
            break  
        except KeyboardInterrupt:
            print("Turning off camera.")
            webcam.release()
            print("Camera off.")
            print("Program ended.")
            cv2.destroyAllWindows()
            break
    else:
        continue
