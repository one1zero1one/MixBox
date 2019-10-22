# Mixbox (2011)

It's a wooden box with two potentiometers and a lcd display running arduino with ethernet shield and talking OSC.

![mixbox](https://user-images.githubusercontent.com/724604/67328930-7573f800-f51a-11e9-9d03-46f83416503a.png)

The box can be used to interact virtually to any appliance that speaks OSC. It could for example - control the pong paddles or be used to fine tune the music. I used it at [Databending](http://2011.gogbot.nl/en/programma/symposium/189-databending.html) to calibrate the other instalation [here](https://github.com/one1zero1one/Younokio).

## How to build it

I used [this](http://www.arduino.cc/en/Tutorial/LiquidCrystal)) tutorial to connect the LCD. It is easier to solder some of the stuff, so I learned. However, I have build the box big enough to host a breadboard.

To enable OSC, I used [Recotana's OSC Library](http://recotana.com/recotanablog/closet) 

The part I spent most time with, was actually writing a menu code for the arduino's LCD and the buttons and potentiometers (using one potentiometer for left-right and two buttons for ok and cancel).
