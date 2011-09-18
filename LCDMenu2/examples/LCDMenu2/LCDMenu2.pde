//# Include
//# ==================================
    #include <LiquidCrystal.h>
    #include <Menu.h>
    #include <LCDMenu2.h>

//# Define
//# ==================================
    #define _LCD_rows       4
    #define _LCD_cols       20
  
    #define _BUTTON_up      8
    #define _BUTTON_down    9
    #define _BUTTON_enter   10
    #define _BUTTON_back    11
    
    #define _BUTTON_prestat 0
   
    #define _BUTTON_press_time  250


  

//# Own Chars
//# ==================================
    uint8_t arrow_up[8]    = {0x4,0xE,0x15,0x4,0x4,0x4,0x0};
    uint8_t arrow_down[8]  = {0x0,0x4,0x4,0x4,0x15,0xE,0x4};

//# Classes
//# ==================================
    LiquidCrystal lcd(2,3,4,5,6,7); // Neuste Version, RW wird nicht mehr gebraucht 

    Menu top("Root");

    // menu, lcd, rows, cols, arrow_up_pos, arrow_down_pos
    LCDMenu2 Root(top, lcd , _LCD_rows, _LCD_cols, 0, 1);

//# Buttons
//# ==================================
    //UP,DOWN,ENTER,BACK
    int but[4]= {_BUTTON_up,_BUTTON_down,_BUTTON_enter,_BUTTON_back};
    //Previous States of buttons
    boolean pbut[4]={_BUTTON_prestat,_BUTTON_prestat,_BUTTON_prestat,_BUTTON_prestat};
  
//# Button Enter
//# ==================================
    int button_press_enter = 0;
    unsigned long g_button_press_time = millis();

//# Menu
//# ==================================
    Menu Item1("Something");
    Menu Item11("Stuff");
    Menu Item12("More");
    Menu Item121("Deeper");
    Menu Item2("Other");
    Menu Item3("Etc");
    Menu Item31("So On");


//# Function
//# ==================================

    //## Menu Init
    void menuinit()
    {
        top.addChild(Item1);
        top.addChild(Item2);
        top.addChild(Item3);
        Item1.addChild(Item11);
        Item1.addChild(Item12);
        Item12.addChild(Item121);
        Item3.addChild(Item31);

        Root.display();
    }    

    //## Button
    void button(int which, char select='z')
    {
        if(which == _BUTTON_up || select == 'w') {
            //UP
            Root.goUp();
            Serial.println("'up'");
        }
        else if(which == _BUTTON_down || select == 's') {
           //DOWN
           Root.goDown();
           Serial.println("'down'");
        }
        else if(which == _BUTTON_enter || select == 'e') {
           //ENTER
           Root.goEnter();
           button_press_enter = 1;
           Serial.println("'enter'");
        }
        else if(which == _BUTTON_back || select == 'q') {
           //BACK
           Root.goBack();
           Serial.println("'back'");
        }
    }
    
    //## Button Check
    void buttoncheck()
    {
        for (int i=0;i<=3;i++)
        {
            if (digitalRead(but[i])) {          
                if (pbut[i]==0 && (millis()-g_button_press_time) >= _BUTTON_press_time) {                  
                    button(but[i]);
                    pbut[i]=1;
                    g_button_press_time = millis();
                }
            }
            else {
                pbut[i]=0;
            }
        }
        if(Serial.available()) {
            char c = Serial.read();
            button(-1,c);
        } 
    }

    //## Function Check
    void funccheck()
    {
        if(button_press_enter == 1) {
            button_press_enter = 0;
            
            if(Root.curfuncname == "Stuff") {
                Serial.println("Function: Stuff");
            }
            else if(Root.curfuncname == "More") {
                Serial.println("Function: More");
            }
            else if(Root.curfuncname == "Other") {
                Serial.println("Function: Other");
            }
            else if(Root.curfuncname == "So on") {
                Serial.println("Function: So on");
            }          
        }
    }


//# Setup
//# ==================================
    void setup()
    {
        lcd.begin(_LCD_rows,_LCD_cols);
        lcd.createChar(0, arrow_up);
        lcd.createChar(1, arrow_down);  
        menuinit();

        Serial.begin(9600);
        Serial.println("DEBUG:");
        Serial.println("================");
    }

//# LOOP
//# ==================================
    void loop()
    {
        buttoncheck();
        funccheck();
    }
