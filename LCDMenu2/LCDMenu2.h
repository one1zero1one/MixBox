//# Info
//# =======================
//- Autor:   Jomelo
//- ICQ:     78048329
//- License: all Free
//- Lastedit:10.09.2009

//# Define
//# =======================
#ifndef LCDMenu2_h
#define LCDMenu2_h

//# Include
//# =======================
#include "WProgram.h"
#include <../Menu/Menu.h>
#include <../LiquidCrystal/LiquidCrystal.h>

//# Lcd Menu 2
//# =======================
class LCDMenu2
{
    private:
        LiquidCrystal * lcd;
        Menu * rootMenu;
        Menu * curMenu;     

        int cols;               // Spalten
        int rows;               // Reihen
        
        int layer_save[8];      // Speichert Cursor Position bis zur 6 Ebene
        int layer;              // Ebenen
        int back;               // Zwischenspeicher

        int arrow_up;           // Position in DisplayCach
        int arrow_down;         // Position in DisplayCach                 
       
        int curloc;             // Aktuelle Cursor Position
        int scroll;             // Aktuelle Scroll Position

        int cursor_pos;         // Speichert die letze Cursor position
    public:
        char * curfuncname;     // Speicher den letzten Funktionsnamen
        char * funcname[5];     // Speicher die letzten Funktionsnamen, bis zur 3 Ebene       
        
        LCDMenu2(Menu &r,LiquidCrystal &d, int row, int cols, int a_up, int a_down);

        void setCursor();       // Setz den Cursor
        void doScroll();        // Scrollt zur passenden Stelle
        void goMenu(Menu &m);   // Go to Menu m
       
        void goUp();            // Move cursor up
        void goDown();          // Move cursor down
        void goBack();          // Move to the parent Menu
        void goEnter();         // Activate the Menu under the cursor
        
        void display();         // Display the current menu on the LCD         
};
#endif                          // end LCDMenu2_h