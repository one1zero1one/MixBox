//# Info
//# =======================
//- Autor:   Jomelo
//- ICQ:     78048329
//- License: all Free
//- Edit:    2009.09.11

//#include "WProgram.h"
#include "LCDMenu2.h"


LCDMenu2::LCDMenu2(Menu &r,LiquidCrystal &d, int ro, int co, int a_up, int a_down)
{
    rootMenu        = &r;
    curMenu         = rootMenu;
    lcd             = &d;
    back            = 0;
    cols            = co;
    rows            = ro;
    arrow_up        = a_up;
    arrow_down      = a_down;
    cursor_pos      = 0;
    layer           = 0;
    layer_save[0]   = 0;
}

void LCDMenu2::setCursor()
{
    if(cursor_pos > curloc-scroll) {
        lcd->setCursor(0,cursor_pos);
        lcd->write(0x20);
    }
    else if(cursor_pos < curloc-scroll) {
       lcd->setCursor(0,curloc-scroll-1);
       lcd->write(0x20);
    }
    cursor_pos = curloc-scroll;

    lcd->setCursor(0,curloc-scroll);
    lcd->write(0x7E);
}

void LCDMenu2::doScroll()
{
    if (curloc<0) {
        curloc=0;
    }
    else {
        while (curloc>0&&!curMenu->getChild(curloc))//Only allow it to go up to Menu item (one more if back button enabled)
        {
            curloc--;
        }
    }

    if (curloc>=(rows+scroll)) {
        scroll++;
        display();
    }
    else if (curloc<(scroll)) {
        scroll--;
        display();
    }
    else {
        setCursor();
    }
}

void LCDMenu2::goUp()
{
    curloc-=1;
    doScroll();
}

void LCDMenu2::goDown()
{
    curloc+=1;
    doScroll();
}

void LCDMenu2::goBack()
{
    if(layer > 0) {
        back = 1;
        goMenu(*curMenu->getParent());
    }

}

void LCDMenu2::goEnter()
{
    Menu *tmp;
    tmp=curMenu;
    if ((tmp=tmp->getChild(curloc))) {//The child exists
        if (tmp->canEnter) {//canEnter function is set
            if (tmp->canEnter(*tmp)) {//It wants us to enter
                goMenu(*tmp);
            }
        }
        else {//canEnter function not set, assume entry allowed
            goMenu(*tmp);
            curfuncname = tmp->name;
        }
    }
    else {//Child did not exist  The only time this should happen is one the back Menu item, so go back
        goBack();
    }
}



void LCDMenu2::goMenu(Menu &m)
{
    curMenu=&m;

    if(layer < 8) {
        int diff;
        scroll = 0;

        if(back == 0) {
            layer_save[layer] = curloc;
            layer++;
            curloc = 0;
        } else {
            back = 0;

            if(layer > 0) {
                layer--;
                curloc = layer_save[layer];

                if(curloc >= rows) {
                    diff = curloc-(rows-1);
                    for(int i=0; i<diff; i++) {
                        doScroll();
                    }
                }
            }
        }
    }


    if(layer >= 0 && layer <5) {
      funcname[layer-1] = curMenu->name;
    }


    display();
}

void LCDMenu2::display()
{
    Menu * tmp;
    int i = scroll;
    int j = 0;
    int maxi=(rows+scroll);

    lcd->clear();

    // Anzahl ermitteln
    if ((tmp=curMenu->getChild(0))) {
        do {
            j++;
        } while ((tmp=tmp->getSibling(1)));
    }
    j--; // Korrektur

    if ((tmp=curMenu->getChild(i))) {
        do {
            lcd->setCursor(0,i-scroll);
            lcd->write(0x20);
            lcd->print(tmp->name);
            i++;

        } while ((tmp=tmp->getSibling(1))&&i<maxi);


        // edit 11.09.2009
        if(j>(rows-1)) {
          // edit end

            if(curloc == 0) {
                lcd->setCursor((cols-1),(rows-1));
                lcd->print(arrow_down, BYTE);
            }
            else if(curloc == j) {
                lcd->setCursor((cols-1),0);
                lcd->print(arrow_up, BYTE);
            }
            else {
                lcd->setCursor((cols-1),0);
                lcd->print(arrow_up, BYTE);

                lcd->setCursor((cols-1),(rows-1));
                lcd->print(arrow_down, BYTE);
            }
        }
    }
    else { // no children
        goBack();
        // function can work
    }
    setCursor();
}