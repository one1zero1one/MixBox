// OSC box for databending gogbot 2011
// using - OSCClass version 1.0.1 (Arduino ver0014)


#include <SPI.h>
#include "Ethernet.h"
#include "OSCClass.h"
#include <LiquidCrystal.h>
#include <MenuBackend.h>    //MenuBackend library - copyright by Alexander Brevig

//global network
byte serverMac[] = { 
  0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte serverIp[]  = { 
    192, 168, 1, 61 }; //himself
int  serverPort  = 8000;
byte gateway[]   = { 
  192, 168, 1, 1 };
byte subnet[]    = { 
  255, 255, 255, 0 };
  
//global OSC
byte destIp[]  = { 
   192, 168, 1, 60};  //linux
   //10, 0, 0, 120};  //server databending
int  destPort = 8000;
char *topAddress="/mixbox";

OSCMessage recMes;
OSCMessage sendMes;
OSCClass osc(&recMes);

//global PINS
const int buttonPinEnter = 3;     // pin for the Enter button
const int buttonPinEsc = 4;     // pin for the Esc button
const int touchPin = A5;        // pin for the touch buttons
const int potPin = A4;          // pin for the potentiometer (left right)
const int potLeftPin=A3;
const int potRightPin=A5;

//maybe it works
double potCenter, potLeft, potRight;

//analog helpers at boot
int lastPotReading;

int lastButtonPushed = 0;

int lastButtonEnterState = HIGH;   // the previous reading from the Enter input pin
int lastButtonEscState = HIGH;   // the previous reading from the Esc input pin
int lastButtonLeftState = HIGH;   // the previous reading from the Left input pin
int lastButtonRightState = HIGH;   // the previous reading from the Right input pin

//debounce
long lastEnterDebounceTime = 0;  // the last time the output pin was toggled
long lastEscDebounceTime = 0;  // the last time the output pin was toggled
long lastLeftDebounceTime = 0;  // the last time the output pin was toggled
long lastRightDebounceTime = 0;  // the last time the output pin was toggled
long debounceDelay = 100;    // the debounce time

//potentiometer step
int potStep = 25; // 0...1024

//global display
LiquidCrystal lcd(14, 15, 10, 9, 8, 7);

//Menu variables
MenuBackend menu = MenuBackend(menuUsed,menuChanged);
//initialize menuitems
MenuItem analyse = MenuItem  ("1. analyse o_O  "); // >@ get-look
MenuItem tweak = MenuItem    ("2. tweak   O_0  "); // #< play-send
MenuItem tweakSend = MenuItem("3. send    o_o    ");//>@#< get-tweak-send
MenuItem config = MenuItem   ("4. config  x_x    ");//>@#< get-tweak-send
MenuItem configPot = MenuItem("4.1 Pot. step   ");
MenuItem configDeb = MenuItem("4.2 Deb. delay  ");
MenuItem configNet = MenuItem("4.3 network conf");
MenuItem configOSC = MenuItem("4.4 config OSC. ");


//Global program logic variables
boolean inExecution = false;
boolean applied = false;

void setup() {

  //pins
  pinMode(buttonPinEsc, INPUT);
  pinMode(buttonPinEnter, INPUT);
  pinMode(potPin, INPUT);
  lastPotReading = digitalRead(potPin); //boot helper
  //pinMode(touchPin, INPUT);
  //digitalWrite(touchPin, HIGH);
  pinMode(potLeftPin, INPUT);
  pinMode(potRightPin, INPUT);

  lcd.begin(16, 2);

  //configure menu
  menu.getRoot().add(analyse);

  //first level
  analyse.addRight(tweak);
  tweak.addRight(tweakSend);
  tweakSend.addRight(config);
  config.addRight(analyse);
  analyse.addLeft(config);

  // make sure there is up everywhere so far
  tweak.addBefore(menu.getRoot());
  analyse.addBefore(menu.getRoot());
  tweakSend.addBefore(menu.getRoot());
  config.addBefore(menu.getRoot());

  //submenu config
  config.addAfter(configPot);
  config.addAfter(configDeb);
  config.addAfter(configNet);
  config.addAfter(configOSC);
  configPot.addRight(configDeb);
  configDeb.addRight(configNet);
  configNet.addRight(configOSC);
  configOSC.addRight(configPot);


  menu.toRoot();

  initLcdRoot();
  
  Ethernet.begin(serverMac ,serverIp ,gateway ,subnet);
  
  osc.begin(serverPort);
  osc.flush();
  
  sendMes.setIp( destIp );
  sendMes.setPort( destPort );
  sendMes.setTopAddress(topAddress);

  //debug
  Serial.begin(9600);

}

void loop() {

  readButtons();  //I splitted button reading and navigation in two procedures because 
  navigateMenus();  //in some situations I want to use the button for other purpose (eg. to change some settings)

}


void  readButtons() {

  int reading;
  int buttonEnterState=HIGH ;            // the current reading from the Enter input pin
  int buttonEscState=HIGH;             // the current reading from the input pin
  int buttonLeftState=HIGH;             // the current reading from the input pin
  int buttonRightState=HIGH;             // the current reading from the input pin


  //   int reading_enter=HIGH;
  //   int reading_esc=HIGH;
  //todo    
  ////Code for getting the 2 virtual buttons out of the touch
  //reading = analogRead(touchPin);
  ////   Serial.println(reading);
  //if (reading > 500 && reading < 990) { //upper part - enter
  //  reading_enter = LOW;
  //} else if (reading < 500) { //lower part - escap
  //  reading_esc = LOW;
  //}


  //Enter button
  reading = digitalRead(buttonPinEnter);
  //    Serial.println(millis() - lastEnterDebounceTime);
  //Serial.println(reading);
  if (reading != lastButtonEnterState) {
    // reset the debouncing timer
    lastEnterDebounceTime = millis();
  } 

  if ((millis() - lastEnterDebounceTime) > debounceDelay) {
    buttonEnterState=reading;
    lastEnterDebounceTime=millis();
  }
  lastButtonEnterState = reading;


  //Esc button               
  reading = digitalRead(buttonPinEsc);
  //Serial.print("esc");
  //Serial.println(reading);
  if (reading != lastButtonEscState) {
    // reset the debouncing timer
    lastEscDebounceTime = millis();
  } 

  if ((millis() - lastEscDebounceTime) > debounceDelay) {
    buttonEscState = reading;
    lastEscDebounceTime=millis();
  }
  lastButtonEscState = reading; 


  //Left and right via potentiometer               
  // read the state of the switch into a local variable:
  reading = analogRead(potPin);
  //Serial.println(reading);
  // if the twist was positive and over step
  if ( reading > lastPotReading && ((reading - lastPotReading) > potStep))
  {
    buttonRightState = LOW;
    lastPotReading = reading; 
  }
  // if the twist was negative and over step
  else if ( reading < lastPotReading && (( lastPotReading - reading) > potStep))
  {
    buttonLeftState = LOW;
    lastPotReading = reading; 
  }  
  // if there was twist but not step
  else if (reading != lastPotReading) {
    //remain high
  }    

  //records which button has been pressed
  if (buttonEnterState==LOW){
    lastButtonPushed=buttonPinEnter; 

  }
  else if(buttonEscState==LOW){
    lastButtonPushed=buttonPinEsc; 

  }
  else if(buttonRightState==LOW){
    lastButtonPushed=101;

  }
  else if(buttonLeftState==LOW){
    lastButtonPushed=102;

  }
  else{
    lastButtonPushed=100; //null

  }                  
}

// this is where the LCD gets updated
// buttons are interpreted (special cases for apply and escape)

void navigateMenus() {
  MenuItem currentMenu=menu.getCurrent();
  switch (lastButtonPushed){
  case buttonPinEnter:
    Serial.println("down");
    if(!(currentMenu.moveDown())){  //if the current menu has a child and has been pressed enter then menu navigate to item below
      menu.use();
    }
    else{  //otherwise, if menu has no child and has been pressed enter the current menu is used
      menu.moveDown();
    } 
    break;
  case buttonPinEsc:
    Serial.println("esc");
    if (inExecution) {
      inExecution = false;
      menu.toSelf();
    } 
    else {
      menu.moveUp(); 
    }
    break;
  case 101:
    menu.moveRight();
    Serial.println("right");
    break;      
  case 102:
    menu.moveLeft();
    Serial.println("left");
    break;   
  default:          
    if (inExecution && applied) {
      Serial.println("after apply, reuse");
      inExecution = false;
      applied = false;
      menu.use();
    }
    break;   
  }

  lastButtonPushed=0; //reset the lastButtonPushed variable
}


void menuChanged(MenuChangeEvent changed){

  MenuItem newMenuItem=changed.to; //get the destination menu

  // display it
  if(newMenuItem.getName()==menu.getRoot()){ //if root init
    initLcdRoot();
  }
  else{
    if ((changed.from.getName() == changed.to.getName())&&(newMenuItem.getBefore()->getName() != config.getName())) {  //when back from execution
      lcd.setCursor(0,0);  
      lcd.print("wellcome back!!!");
      lcd.setCursor(0,1);
      lcd.print("mixbox missed u!");
      delay(1000);
    }

    // display parent menu
    lcd.setCursor(0,0);  
    lcd.print(newMenuItem.getBefore()->getName());

    // display down the current menu
    lcd.setCursor(0,1);
    lcd.print(changed.to.getName());
  } 
}

// this is where the program hapens
// --------------------------------
void menuUsed(MenuUseEvent used){

  inExecution = true;  //tell the rest of program we're here
  boolean exit = false; // escape 
  long last,last_fast;   // used for screen time (to avoid delay messing up)
  int potStepTemp;  // used in config pot
  int debounceDelayTemp; // used in config deb



  // try to keep TOP pointing to menu and use the bottom.
  lcd.setCursor(0,0);
  lcd.print(used.item.getName());
  lcd.setCursor(0,1);

  // logic for menus
  //Options-ConfigPot        
  if (used.item==configPot) {
    // same as the main loop
    exit = false;
    while (!exit) { 
      //read buttons and potentiometer          
      readButtons(); 

      // sort of navigation logic    
      int reading = analogRead(potPin);
      potStepTemp = int(reading/8);

      //display while updating pot every second  
      if ((millis() - last) > 100) {
        clearPrint("Cur.:",0,1); //5
        clearPrint(String(potStep),5,1); //9
        clearPrint("->",9,1);
        clearPrint(String(potStepTemp),11,1);
        last = millis();
      }
      //interpret ENTER
      if (lastButtonPushed == buttonPinEnter) {
        applied = true;
        potStep = potStepTemp;
        clearPrint("APPLIED",0,1);
        delay(1000);
        break;
      }
      // interpret Stop
      if (lastButtonPushed == buttonPinEsc) {
        break;
      }
      //todo write a timeout using exit
      // end sort of naviation logic

      lastButtonPushed=0; 
    }            
    //Options-ConfigDeb
  } 
  else if (used.item==configDeb) {
    // same as the main loop
    exit = false;
    while (!exit) { 
      //read buttons and potentiometer          
      readButtons(); 

      // sort of navigation logic    
      int reading = analogRead(potPin);
      debounceDelayTemp = int(reading/8);

      //display while updating pot every 100ms   
      if ((millis() - last) > 100) {
        clearPrint("Cur.:",0,1); //5
        clearPrint(String(debounceDelay),5,1); //9
        clearPrint("->",9,1);
        clearPrint(String(debounceDelayTemp),11,1);
        last = millis();
      }
      //interpret ENTER
      if (lastButtonPushed == buttonPinEnter) {
        applied = true;
        debounceDelay = debounceDelayTemp;
        clearPrint("APPLIED",0,1);
        delay(1000);
        break;
      }
      // interpret Stop
      if (lastButtonPushed == buttonPinEsc) {
        break;
      }
      //todo write a timeout using exit
      // end sort of naviation logic

      lastButtonPushed=0; 
    }
     //Options-tweakSend
  } 
  else if (used.item==tweakSend) {
    // same as the main loop
    exit = false;
    char text[5];
    while (!exit) { 
      //read buttons and potentiometer          
      readButtons(); 

      // sort of navigation logic  
      int c = analogRead(potPin);
      int r = analogRead(potRightPin);
      int l = analogRead(potLeftPin);
      potCenter = ((c + 1) * 0.99)/1024;
      potRight =  ((r + 1) * 0.99)/1024;
      potLeft =   ((l + 1) * 0.99)/1024;

      //display while sending OSC every 100ms
       if ((millis() - last) > 5I00) {
        clearPrint(floatToString(text,potLeft,4,2),0,1); //9
        clearPrint(floatToString(text,potCenter,4,2),5,1); //9
        clearPrint(floatToString(text,potRight,4,2),10,1); //9
        last = millis();
        
      } 
      
        sendMes.setPort( destPort );
        sendMes.setIp(  destIp );       
        sendMes.setSubAddress("/out/potfine");
        sendMes.setArgs("f" ,&potCenter);
        osc.sendOsc( &sendMes );  
        sendMes.setSubAddress("/out/potleft");
        sendMes.setArgs("f" ,&potLeft);
        osc.sendOsc( &sendMes );  
        sendMes.setSubAddress("/out/potright");
        sendMes.setArgs("f" ,&potRight);
        osc.sendOsc( &sendMes ); 

      
//      //interpret ENTER
//      if (lastButtonPushed == buttonPinEnter) {
//        applied = true;
//        debounceDelay = debounceDelayTemp;
//        clearPrint("APPLIED",0,1);
//        delay(1000);
//        break;
//      }
      // interpret Stop
      if (lastButtonPushed == buttonPinEsc) {
        lastButtonPushed=0; 
        break;
      }
      //todo write a timeout using exit
      // end sort of naviation logic

      lastButtonPushed=0; 
    } 
  } 
  else {  
    // no defined action
    lcd.setCursor(0,1);
    lcd.print("here we do stuff");
  }
}



// root
void initLcdRoot(){
  lcd.setCursor(0,0);
  lcd.print("* MixBox v4.0 *");
  lcd.setCursor(0,1);
  lcd.print("Root            ");
}

// function to lcd.print with proper clear before
void clearPrint(String text, int pos, int line ) {
  lcd.setCursor(pos,line);
  lcd.print("               ");
  lcd.setCursor(pos,line);
  lcd.print(text);
}

char * floatToString(char * outstr, double val, byte precision, byte widthp){
  char temp[16];
  byte i;

  // compute the rounding factor and fractional multiplier
  double roundingFactor = 0.5;
  unsigned long mult = 1;
  for (i = 0; i < precision; i++)
  {
    roundingFactor /= 10.0;
    mult *= 10;
  }
  
  temp[0]='\0';
  outstr[0]='\0';

  if(val < 0.0){
    strcpy(outstr,"-\0");
    val = -val;
  }

  val += roundingFactor;

  strcat(outstr, itoa(int(val),temp,10));  //prints the int part
  if( precision > 0) {
    strcat(outstr, ".\0"); // print the decimal point
    unsigned long frac;
    unsigned long mult = 1;
    byte padding = precision -1;
    while(precision--)
      mult *=10;

    if(val >= 0)
      frac = (val - int(val)) * mult;
    else
      frac = (int(val)- val ) * mult;
    unsigned long frac1 = frac;

    while(frac1 /= 10)
      padding--;

    while(padding--)
      strcat(outstr,"0\0");

    strcat(outstr,itoa(frac,temp,10));
  }

  // generate space padding
  if ((widthp != 0)&&(widthp >= strlen(outstr))){
    byte J=0;
    J = widthp - strlen(outstr);
    
    for (i=0; i< J; i++) {
      temp[i] = ' ';
    }

    temp[i++] = '\0';
    strcat(temp,outstr);
    strcpy(outstr,temp);
  }
  
  return outstr;
} 

