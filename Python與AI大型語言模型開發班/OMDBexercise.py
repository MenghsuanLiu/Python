import requests
from tkinter import *
from io import BytesIO
from PIL import Image, ImageTk
from urllib.request import urlopen



# pip install requests
# pip install pillow




root = Tk()


imageURL = "https://static.amazon.jobs/teams/53/thumbnails/IMDb_Jobs_Header_Mobile.jpg?1501027253"



def displayPic(imageURL):
    global label1
    url = urlopen(imageURL)     # grabs object from a web URL location and converts it into a Python object
    imageData = url.read()      # grab the RAW DATA from the python object
    url.close()

    image = Image.open(   BytesIO(imageData)    )   # convert image data into a Pillow Image object.
    photo = ImageTk.PhotoImage(image)               # convert pillow image into a Tk image that can be used in Tkinter

    label1.configure(image=photo)                   # set the dimensions of the label to match dimensions of photo
    label1.image = photo                            # set the image property of the label as our image




def searchFunc():
    search = searchEntry.get()
    year = yearEntry.get()
    
    myURL = "https://www.omdbapi.com/?apikey=5964f155&s=" + search + "&y=" + year
    response = requests.get(url=myURL)
    firstRecord = response.json()["Search"][0]

    posterURL = firstRecord["Poster"]

    print(posterURL)
    
    
    displayPic(posterURL)










Label(root, text="Search").grid(row=0, column=0)
searchEntry = Entry(root)
searchEntry.grid(row=0, column=1)

Label(root, text="Year").grid(row=1, column=0)
yearEntry = Entry(root)
yearEntry.grid(row=1, column=1)

Button(root, text="Search", command=searchFunc).grid(row=2, column=0)

label1 = Label(root)
label1.grid(row=4, column=3)










displayPic(imageURL)


root.mainloop()

