package com.ghostatlas.homeward;

import android.content.Context;
import android.graphics.*;
import android.os.Build;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.view.MotionEvent;
import android.view.View;
import java.util.ArrayList;
import java.util.Random;

public final class GameView extends View implements Runnable {
    private final Paint p=new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint text=new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint stroke=new Paint(Paint.ANTI_ALIAS_FLAG);
    private final GameCore core=new GameCore();
    private final WorldModel world=new WorldModel();
    private final SaveSystem save;
    private final AudioEngine audio=new AudioEngine();
    private final Vibrator vibrator;
    private final Random rng=new Random(50503);
    private final ArrayList<Spark> sparks=new ArrayList<>();
    private Thread loop;
    private volatile boolean running=true;
    private float sw,sh,scale=1f,viewW=1600f,cam=0f,px=GameCore.START_X,py=610f;
    private float stickX=0f,stickY=0f,messageT=0f,akhet=0f,rainbow=0f,saveClock=0f,clock=0f;
    private int stickId=-1,hamsaHarvests=0;
    private boolean title=true,alchemy=false,journal=false,won=false;
    private String speaker="",message="";
    private static final int[] RAINBOW={0xffff6aa8,0xffffd56f,0xff8df08e,0xff66e0df,0xff70a7ff,0xffc181ff};
    private static final int[][] ZONE={
        {0xff0b1738,0xff126678,0xff2c9e91},
        {0xff17133c,0xff3d3b70,0xff4a8b7b},
        {0xff28143d,0xff7b3e55,0xffc47c62},
        {0xff0b1f49,0xff24558d,0xff38a9b8},
        {0xff17123d,0xff624b8c,0xffd9956f}
    };

    static final class Spark{
        float x,y,vx,vy,life,r; int color;
        Spark(float x,float y,float vx,float vy,float life,float r,int color){this.x=x;this.y=y;this.vx=vx;this.vy=vy;this.life=life;this.r=r;this.color=color;}
    }

    public GameView(Context c){
        super(c);
        setKeepScreenOn(true);setFocusable(true);
        save=new SaveSystem(c);
        vibrator=(Vibrator)c.getSystemService(Context.VIBRATOR_SERVICE);
        text.setTypeface(Typeface.create("sans-serif-condensed",Typeface.BOLD));
        stroke.setStyle(Paint.Style.STROKE);stroke.setStrokeWidth(3f);
        if(save.hasSave()){save.load(core,world);px=Math.max(GameCore.START_X,save.loadX());won=core.isWon();}
    }

    @Override protected void onAttachedToWindow(){super.onAttachedToWindow();running=true;audio.start();if(loop==null||!loop.isAlive()){loop=new Thread(this,"homeward-loop");loop.start();}}
    @Override protected void onDetachedFromWindow(){saveNow();running=false;audio.stop();if(loop!=null)loop.interrupt();super.onDetachedFromWindow();}
    public void pauseGame(){saveNow();audio.pause();}
    public void resumeGame(){audio.start();}
    private void saveNow(){save.save(core,world,px);}

    @Override protected void onSizeChanged(int w,int h,int ow,int oh){sw=w;sh=h;scale=Math.max(.48f,sh/900f);viewW=sw/scale;}
    @Override public void run(){
        long last=System.nanoTime();
        while(running){
            long now=System.nanoTime();float dt=Math.min(.033f,(now-last)/1_000_000_000f);last=now;clock+=dt;
            if(!title&&!won&&!alchemy&&!journal)update(dt);
            postInvalidate();
            try{Thread.sleep(16);}catch(InterruptedException ignored){}
        }
    }

    private void update(float dt){
        messageT=Math.max(0,messageT-dt);akhet=Math.max(0,akhet-dt);rainbow=Math.max(0,rainbow-dt);
        saveClock+=dt;if(saveClock>8f){saveClock=0;saveNow();}
        float m=(float)Math.sqrt(stickX*stickX+stickY*stickY);
        if(m>.08f){
            float nx=stickX/Math.max(1f,m),ny=stickY/Math.max(1f,m);
            float speed=315f*(rainbow>0?1.55f:1f)*(core.isCrafted(GameCore.STARLIGHT_SOUP)?1.12f:1f);
            px=core.constrainX(px,px+nx*speed*dt);py=Math.max(265f,Math.min(785f,py+ny*speed*dt));
        }
        cam=Math.max(0f,Math.min(GameCore.WORLD_W-viewW,px-viewW*.31f));
        if(rainbow>0&&rng.nextFloat()<.45f)spawn(px,py-30,RAINBOW[rng.nextInt(RAINBOW.length)],1.2f);
        for(int i=sparks.size()-1;i>=0;i--){Spark s=sparks.get(i);s.x+=s.vx*dt;s.y+=s.vy*dt;s.life-=dt;if(s.life<=0)sparks.remove(i);}
        if(core.evaluateHome(px)&&!won){won=true;saveNow();audio.home();vibe(90);for(int i=0;i<80;i++)spawn(px,520+rng.nextInt(180),RAINBOW[i%RAINBOW.length],2.4f);}
    }

    @Override protected void onDraw(Canvas c){
        super.onDraw(c);
        if(title){drawTitle(c);return;}
        c.save();c.scale(scale,scale);drawWorld(c);c.restore();drawHud(c);
        if(messageT>0)drawMessage(c);if(alchemy)drawAlchemy(c);if(journal)drawJournal(c);if(won)drawWin(c);
    }

    private void drawTitle(Canvas c){
        LinearGradient g=new LinearGradient(0,0,0,sh,new int[]{0xff05091d,0xff143b65,0xff176b73},null,Shader.TileMode.CLAMP);p.setShader(g);c.drawRect(0,0,sw,sh,p);p.setShader(null);
        for(int i=0;i<65;i++){float x=(i*137)%Math.max(1,(int)sw),y=(i*79)%Math.max(1,(int)(sh*.55f));p.setColor(0x99d7f7ff);c.drawCircle(x,y,1+(i%3),p);}
        drawSkyline(c,sh*.62f);
        text.setTextAlign(Paint.Align.CENTER);text.setColor(0xffffd56f);text.setTextSize(Math.min(60f,sw*.062f));c.drawText("NEW ATLANTIS: HOMEWARD",sw/2,sh*.27f,text);
        text.setColor(0xff9effef);text.setTextSize(Math.min(18f,sw*.021f));c.drawText("GHOST ATLAS • NHCM 5.0 • TIER 3",sw/2,sh*.34f,text);
        text.setColor(Color.WHITE);text.setTextSize(Math.min(20f,sw*.023f));c.drawText("FORAGE • ALCHEMIZE • LEARN • GET HOME TO THE TRIBE",sw/2,sh*.44f,text);
        p.setColor(0xff157a83);c.drawRoundRect(sw*.31f,sh*.69f,sw*.69f,sh*.83f,28,28,p);stroke.setColor(0xffb5fff5);c.drawRoundRect(sw*.31f,sh*.69f,sw*.69f,sh*.83f,28,28,stroke);
        text.setColor(Color.WHITE);text.setTextSize(Math.min(23f,sw*.026f));c.drawText(save.hasSave()?"CONTINUE HOMEWARD":"BEGIN HOMEWARD",sw/2,sh*.775f,text);
    }

    private void drawSkyline(Canvas c,float horizon){
        p.setColor(0xff0c334c);c.drawRect(0,horizon,sw,sh,p);
        for(int i=0;i<18;i++){float x=sw*i/17f,h=45+(i%5)*22;p.setColor(i%2==0?0xff103f58:0xff154861);c.drawRect(x-24,horizon-h,x+24,horizon,p);p.setColor(0xff67e8d5);c.drawRect(x-2,horizon-h-18,x+2,horizon-h+5,p);}
        p.setColor(0xff1e5871);Path t=new Path();t.moveTo(sw*.43f,horizon);t.lineTo(sw*.50f,horizon-145);t.lineTo(sw*.57f,horizon);t.close();c.drawPath(t,p);
    }

    private void drawWorld(Canvas c){
        int zi=zoneIndex(px),[]colors=ZONE[zi];
        LinearGradient sky=new LinearGradient(0,0,0,700,colors,null,Shader.TileMode.CLAMP);p.setShader(sky);c.drawRect(0,0,viewW,700,p);p.setShader(null);
        for(int i=0;i<48;i++){float x=(i*293f-cam*.08f)%viewW;if(x<0)x+=viewW;float y=42+(i*83)%330;p.setColor(0x88ddf8ff);c.drawCircle(x,y,1+(i%2),p);}
        drawParallax(c,zi);drawGround(c,zi);drawResources(c);drawCauldrons(c);drawHelpers(c);drawWizards(c);drawGates(c);drawHome(c);drawPlayer(c);
        for(Spark s:sparks){if(s.x<cam-70||s.x>cam+viewW+70)continue;p.setColor(s.color);c.drawCircle(s.x-cam,s.y,s.r,p);}
    }

    private void drawParallax(Canvas c,int zi){
        Path far=new Path();far.moveTo(0,620);for(int x=0;x<=viewW+200;x+=200){float peak=470-65*(float)Math.sin((x+cam*.15f)*.004+zi);far.lineTo(x+100,peak);far.lineTo(x+200,620);}far.lineTo(viewW,660);far.lineTo(0,660);far.close();p.setColor(Color.argb(150,25+zi*7,48+zi*8,75+zi*7));c.drawPath(far,p);
        for(int i=0;i<16;i++){float wx=350+i*450,x=wx-cam*.45f;if(x<-100||x>viewW+100)continue;float y=235+(i%4)*55;p.setColor(0x884d8d9d);c.drawOval(x-58,y,x+58,y+18,p);c.drawRect(x-12,y-55,x+12,y,p);p.setColor(0xff8bfff0);c.drawCircle(x,y-60,5,p);}
        for(int i=0;i<26;i++){float wx=80+i*300,x=wx-cam*.74f;if(x<-80||x>viewW+80)continue;float h=85+(i%5)*34;p.setColor(0xcc123c55);c.drawRect(x-30,635-h,x+30,635,p);p.setColor(0xaa71e6d4);c.drawRect(x-2,635-h-15,x+2,635-h+4,p);}
    }

    private void drawGround(Canvas c,int zi){
        p.setColor(zi==0?0xff174f4c:zi==1?0xff263752:zi==2?0xff61433f:zi==3?0xff174c60:0xff55445d);c.drawRect(0,640,viewW,900,p);
        p.setColor(0xff78d9c3);c.drawRect(0,705,viewW,711,p);p.setColor(0x557ff4dd);c.drawRect(0,716,viewW,719,p);
        for(int i=0;i<30;i++){float wx=i*260,x=wx-cam;if(x<-80||x>viewW+80)continue;p.setColor(0x335effd6);c.drawCircle(x,760+(i%3)*24,20+(i%4)*6,p);}
    }

    private void drawResources(Canvas c){
        for(WorldModel.ResourceNode n:world.resources){if(n.gathered||n.x<cam-80||n.x>cam+viewW+80)continue;float x=n.x-cam,y=n.y;int col=ingredientColor(n.type);p.setColor(Color.argb(55,Color.red(col),Color.green(col),Color.blue(col)));c.drawCircle(x,y,akhet>0?34:22,p);p.setColor(col);
            if(n.type==GameCore.STARSHROOM){c.drawOval(x-16,y-8,x+16,y+9,p);c.drawRect(x-4,y+7,x+4,y+24,p);}else if(n.type==GameCore.CRYSTAL_REED||n.type==GameCore.TIDEGLASS){Path q=new Path();q.moveTo(x,y-22);q.lineTo(x+11,y);q.lineTo(x,y+23);q.lineTo(x-11,y);q.close();c.drawPath(q,p);}else{c.drawCircle(x,y,10+n.rarity*2,p);c.drawRect(x-3,y+8,x+3,y+28,p);}
            if(akhet>0){stroke.setColor(0xffffed9a);stroke.setStrokeWidth(2);c.drawCircle(x,y,30+(float)Math.sin(clock*5+n.id)*5,stroke);}
        }
    }

    private void drawCauldrons(Canvas c){for(WorldModel.Cauldron q:world.cauldrons){if(q.x<cam-100||q.x>cam+viewW+100)continue;float x=q.x-cam,y=q.y;p.setColor(0xff202536);c.drawOval(x-34,y-4,x+34,y+28,p);p.setColor(0xff53e2c9);c.drawOval(x-27,y-9,x+27,y+5,p);for(int i=0;i<3;i++){p.setColor(RAINBOW[i+1]);c.drawCircle(x-12+i*12,y-14-(float)Math.sin(clock*2+i)*7,4,p);}}}

    private void drawHelpers(Canvas c){for(WorldModel.HelperNode h:world.helpers){if(h.x<cam-120||h.x>cam+viewW+120)continue;drawCharacter(c,h.x-cam,h.y,0xfff3b66d,0xff317c78,false,core.isHelperMet(h.index));}}
    private void drawWizards(Canvas c){for(WorldModel.WizardNode w:world.wizards){if(w.x<cam-140||w.x>cam+viewW+140)continue;int robe=w.index==0?0xffd4a85d:w.index==1?0xff28344e:w.index==2?0xff53a786:w.index==3?0xff9f67c6:0xff3e93b5;drawCharacter(c,w.x-cam,w.y,0xffd8a57d,robe,true,core.isWizardMet(w.index));text.setTextAlign(Paint.Align.CENTER);text.setTextSize(11);text.setColor(0xfff5f2df);c.drawText(w.name,w.x-cam,w.y-93,text);}}

    private void drawCharacter(Canvas c,float x,float y,int skin,int robe,boolean wizard,boolean met){
        p.setColor(0x33000000);c.drawOval(x-28,y+32,x+28,y+44,p);p.setColor(robe);Path body=new Path();body.moveTo(x,y-25);body.lineTo(x-25,y+34);body.lineTo(x+25,y+34);body.close();c.drawPath(body,p);p.setColor(skin);c.drawCircle(x,y-42,13,p);p.setColor(0xff171b2b);c.drawCircle(x-5,y-44,2,p);c.drawCircle(x+5,y-44,2,p);
        if(wizard){p.setColor(met?0xffffd86e:0xff82d9d2);Path hat=new Path();hat.moveTo(x-22,y-54);hat.lineTo(x+22,y-54);hat.lineTo(x,y-91);hat.close();c.drawPath(hat,p);p.setColor(0xffd4b46d);c.drawRect(x+24,y-35,x+28,y+28,p);c.drawCircle(x+26,y-39,6,p);}else{p.setColor(0xffd4b46d);c.drawRect(x-18,y-13,x-14,y+27,p);}
        if(met){p.setColor(0x66fff5a8);c.drawCircle(x,y-35,39,p);}
    }

    private void drawGates(Canvas c){float[] gates={1760,3140,4460,5740};for(int i=0;i<gates.length;i++){float x=gates[i]-cam;if(x<-80||x>viewW+80)continue;boolean open=core.isWizardMet(i);p.setColor(open?0x554fffd7:0xaa173a54);c.drawRect(x-16,350,x+16,720,p);p.setColor(open?0xffffe985:0xff6fd4dc);c.drawCircle(x,365,13,p);if(open){for(int j=0;j<5;j++){p.setColor(RAINBOW[j]);c.drawCircle(x,430+j*52,8,p);}}}}

    private void drawHome(Canvas c){float hx=GameCore.HOME_X-cam;if(hx<-300||hx>viewW+350)return;p.setColor(0xff244e67);c.drawRect(hx-200,420,hx+230,715,p);p.setColor(0xffffd56f);Path roof=new Path();roof.moveTo(hx-230,420);roof.lineTo(hx+15,270);roof.lineTo(hx+260,420);roof.close();c.drawPath(roof,p);text.setTextAlign(Paint.Align.CENTER);text.setColor(0xffeafff8);text.setTextSize(23);c.drawText("EDEN COMMONS",hx+15,458,text);
        for(int i=0;i<7;i++){float tx=hx-145+i*52,ty=590+(i%2)*38;drawCharacter(c,tx,ty,0xffd6a17b,RAINBOW[i%RAINBOW.length],false,true);}text.setTextSize(13);text.setColor(0xffffeaa4);c.drawText("YOUR TRIBE IS HERE",hx+15,676,text);
    }

    private void drawPlayer(Canvas c){float x=px-cam,y=py;p.setColor(0x44000000);c.drawOval(x-27,y+28,x+27,y+42,p);if(rainbow>0){for(int i=5;i>=0;i--){p.setColor(Color.argb(55,Color.red(RAINBOW[i]),Color.green(RAINBOW[i]),Color.blue(RAINBOW[i])));c.drawCircle(x,y-30,35+i*5,p);}}p.setColor(0xff123553);Path robe=new Path();robe.moveTo(x,y-28);robe.lineTo(x-25,y+31);robe.lineTo(x+25,y+31);robe.close();c.drawPath(robe,p);p.setColor(0xffd6a47b);c.drawCircle(x,y-44,13,p);p.setColor(0xffffd66f);Path hood=new Path();hood.moveTo(x-17,y-53);hood.lineTo(x+17,y-53);hood.lineTo(x,y-78);hood.close();c.drawPath(hood,p);p.setColor(0xff7ff7e8);c.drawCircle(x,y-34,5,p);}

    private void drawHud(Canvas c){
        text.setTextAlign(Paint.Align.LEFT);p.setColor(0xcc071525);c.drawRoundRect(14,12,sw*.58f,77,18,18,p);text.setColor(0xffffd56f);text.setTextSize(16);c.drawText(world.zoneFor(px).name,28,36,text);text.setColor(0xffbdf9ef);text.setTextSize(11);c.drawText(nextObjective(),28,58,text);
        p.setColor(0xcc071525);c.drawRoundRect(sw-190,12,sw-14,77,18,18,p);text.setTextAlign(Paint.Align.CENTER);text.setColor(Color.WHITE);text.setTextSize(13);c.drawText("JOURNAL",sw-102,36,text);c.drawText("FORAGED "+core.getForageCount(),sw-102,57,text);
        float cx=92,cy=sh-92;p.setColor(0x5531a9a0);c.drawCircle(cx,cy,70,p);stroke.setColor(0x99a6fff4);c.drawCircle(cx,cy,70,stroke);p.setColor(0x887ff6e7);c.drawCircle(cx+stickX*44,cy+stickY*44,27,p);
        float bx=sw-92,by=sh-91;p.setColor(0xcc197c83);c.drawCircle(bx,by,63,p);stroke.setColor(0xffb9fff6);c.drawCircle(bx,by,63,stroke);text.setTextAlign(Paint.Align.CENTER);text.setColor(Color.WHITE);text.setTextSize(14);c.drawText(contextLabel(),bx,by+5,text);
        float start=sw*.38f;for(int i=0;i<4;i++){float x=start+i*70;p.setColor(core.isWizardMet(i)?RAINBOW[i+1]:0x55364c5e);c.drawCircle(x,sh-55,27,p);text.setTextSize(11);text.setColor(core.isWizardMet(i)?0xff07131f:0xff9ab3bf);c.drawText(i==0?"AKH":i==1?"PASS":i==2?"HMSA":"RB",x,sh-51,text);}
    }

    private String nextObjective(){if(!core.isWizardMet(0))return "Gather Moonleaf + Crystal Reed • brew HORIZON TEA • meet the Sphinx";if(!core.isWizardMet(1))return "Gather Starshroom + Moonleaf • brew PASSAGE TONIC • meet Anubis";if(!core.isWizardMet(2))return "Gather Emberberry + Crystal Reed • brew BLESSING OIL • meet Hamsa";if(!core.isWizardMet(3))return "Gather Prism Seed + Starshroom + Emberberry • brew RAINBOW ELIXIR";if(!core.isWizardMet(4))return "Find THOTH on the Eden Approach";return "Walk into EDEN COMMONS • your tribe is waiting";}

    private void drawMessage(Canvas c){p.setColor(0xe60a1729);c.drawRoundRect(sw*.16f,sh*.13f,sw*.84f,sh*.31f,22,22,p);text.setTextAlign(Paint.Align.CENTER);text.setColor(0xffffd66f);text.setTextSize(18);c.drawText(speaker,sw/2,sh*.19f,text);text.setColor(Color.WHITE);text.setTextSize(14);drawWrapped(c,message,sw/2,sh*.235f,sw*.60f,20);}

    private void drawAlchemy(Canvas c){p.setColor(0xf20a1528);c.drawRect(0,0,sw,sh,p);text.setTextAlign(Paint.Align.CENTER);text.setColor(0xffffd56f);text.setTextSize(27);c.drawText("ALCHEMY TABLE",sw/2,65,text);for(int i=0;i<6;i++){int col=i%2,row=i/2;float l=sw*(col==0?.12f:.52f),r=sw*(col==0?.48f:.88f),top=105+row*112;p.setColor(core.isCrafted(i)?0xff255f51:core.canCraft(i)?0xff176f78:0xff26374a);c.drawRoundRect(l,top,r,top+92,16,16,p);text.setColor(core.isCrafted(i)?0xffc7ffe0:Color.WHITE);text.setTextSize(15);c.drawText((core.isCrafted(i)?"✓ ":"")+AlchemySystem.RECIPE_NAMES[i],(l+r)/2,top+32,text);text.setColor(0xffb8d9de);text.setTextSize(11);c.drawText(AlchemySystem.RECIPE_DESC[i],(l+r)/2,top+58,text);}text.setColor(0xff9effef);text.setTextSize(13);c.drawText("Tap a recipe to brew • tap bottom to return",sw/2,sh-44,text);}

    private void drawJournal(Canvas c){p.setColor(0xf20a1528);c.drawRect(0,0,sw,sh,p);text.setTextAlign(Paint.Align.CENTER);text.setColor(0xffffd56f);text.setTextSize(27);c.drawText("HOMEWARD JOURNAL",sw/2,65,text);String[] s={"SPHINX • Horizon Tea","ANUBIS • Passage Tonic","HAMSA • Blessing Oil","RAINBOW ORACLE • Rainbow Elixir","THOTH • four guardian lessons","EDEN COMMONS • home"};boolean[] d={core.isWizardMet(0),core.isWizardMet(1),core.isWizardMet(2),core.isWizardMet(3),core.isWizardMet(4),core.isWon()};for(int i=0;i<s.length;i++){float y=105+i*55;p.setColor(d[i]?0xff276d58:0xff26384b);c.drawRoundRect(sw*.22f,y,sw*.78f,y+42,12,12,p);text.setColor(d[i]?0xffc8ffe0:Color.WHITE);text.setTextSize(14);c.drawText((d[i]?"✓  ":"○  ")+s[i],sw/2,y+27,text);}text.setColor(0xffa7fff2);text.setTextSize(12);c.drawText("FRIENDS MET "+core.helperCount()+"/4 • OPTIONAL HELP ALONG THE ROAD",sw/2,465,text);}

    private void drawWin(Canvas c){LinearGradient g=new LinearGradient(0,0,0,sh,new int[]{0xf20b1737,0xf22b7774,0xf2b17c6b},null,Shader.TileMode.CLAMP);p.setShader(g);c.drawRect(0,0,sw,sh,p);p.setShader(null);for(int i=0;i<60;i++){p.setColor(RAINBOW[i%6]);c.drawCircle((i*97+clock*30)%sw,35+(i*61)%Math.max(1,(int)(sh*.60f)),2+(i%4),p);}text.setTextAlign(Paint.Align.CENTER);text.setColor(0xffffdf86);text.setTextSize(Math.min(60f,sw*.061f));c.drawText("YOU'RE HOME",sw/2,sh*.27f,text);text.setColor(Color.WHITE);text.setTextSize(Math.min(20f,sw*.023f));c.drawText("The map became a road. The road became a garden.",sw/2,sh*.38f,text);c.drawText("Your tribe was waiting.",sw/2,sh*.44f,text);text.setColor(0xffc4fff0);text.setTextSize(14);c.drawText("FORAGED "+core.getForageCount()+" • BREWS "+core.getCraftCount()+" • WIZARDS "+core.wizardCount()+" • FRIENDS "+core.helperCount(),sw/2,sh*.54f,text);p.setColor(0xff168176);c.drawRoundRect(sw*.34f,sh*.67f,sw*.66f,sh*.81f,26,26,p);text.setColor(Color.WHITE);text.setTextSize(18);c.drawText("WALK THE ROAD AGAIN",sw/2,sh*.755f,text);}

    @Override public boolean onTouchEvent(MotionEvent e){
        int a=e.getActionMasked(),idx=e.getActionIndex();
        if(a==MotionEvent.ACTION_DOWN||a==MotionEvent.ACTION_POINTER_DOWN){float x=e.getX(idx),y=e.getY(idx);int id=e.getPointerId(idx);if(title){title=false;audio.gate();return true;}if(won){if(y>sh*.62f){save.clear();core.reset();for(WorldModel.ResourceNode n:world.resources)n.gathered=false;px=GameCore.START_X;py=610;won=false;title=true;}return true;}if(alchemy||journal){if(y>sh-100){alchemy=journal=false;return true;}if(alchemy)handleRecipeTap(x,y);return true;}if(y<90&&x>sw-210){journal=true;return true;}if(x<sw*.25f&&y>sh*.65f){stickId=id;setStick(x,y);return true;}if(x>sw-175&&y>sh*.64f){interact();return true;}if(y>sh-100&&x>sw*.33f&&x<sw*.70f){powerTap(x);return true;}}
        else if(a==MotionEvent.ACTION_MOVE&&stickId!=-1){int pi=e.findPointerIndex(stickId);if(pi>=0)setStick(e.getX(pi),e.getY(pi));return true;}
        else if(a==MotionEvent.ACTION_UP||a==MotionEvent.ACTION_POINTER_UP||a==MotionEvent.ACTION_CANCEL){if(e.getPointerId(idx)==stickId){stickId=-1;stickX=stickY=0;}return true;}
        return true;
    }

    private void setStick(float x,float y){float cx=92,cy=sh-92,dx=(x-cx)/66f,dy=(y-cy)/66f,m=(float)Math.sqrt(dx*dx+dy*dy);if(m>1){dx/=m;dy/=m;}stickX=dx;stickY=dy;}
    private void handleRecipeTap(float x,float y){if(y<105||y>450)return;int col=x<sw/2?0:1,row=(int)((y-105)/112),r=row*2+col;if(r<0||r>=6)return;if(core.craft(r)){audio.brew();vibe(45);announce("ALCHEMY",AlchemySystem.RECIPE_NAMES[r]+" brewed.",2f);saveNow();}else if(core.isCrafted(r))announce("ALCHEMY",AlchemySystem.RECIPE_NAMES[r]+" is already in your kit.",2f);else announce("ALCHEMY","Gather: "+AlchemySystem.RECIPE_DESC[r],2.5f);}

    private void powerTap(float x){float start=sw*.38f;int i=Math.round((x-start)/70f);i=Math.max(0,Math.min(3,i));if(!core.isWizardMet(i)){announce("RUNE DORMANT","Meet the guardian wizard first.",1.8f);return;}if(i==0){akhet=12;announce("AKHET SIGHT","Forage lights across the horizon.",1.8f);}else if(i==1){px=core.constrainX(px,px+470);announce("PASSAGE STEP","Space folds gently forward.",1.6f);}else if(i==2){hamsaHarvests=3;announce("HAMSA BLESSING","Your next three harvests are abundant.",2f);}else{rainbow=12;announce("RAINBOW BODY","Full-spectrum movement online.",2f);}audio.wizard();vibe(35);}

    private void interact(){
        WorldModel.ResourceNode r=nearestResource(120);if(r!=null){int amount=hamsaHarvests>0?2:1;if(hamsaHarvests>0)hamsaHarvests--;r.gathered=true;core.collect(r.type,amount);audio.gather();vibe(25);announce("FORAGED",Inventory.NAMES[r.type]+" ×"+amount,1.4f);for(int i=0;i<12;i++)spawn(r.x,r.y,ingredientColor(r.type),1f);saveNow();return;}
        WorldModel.Cauldron q=nearestCauldron(155);if(q!=null){alchemy=true;audio.gate();return;}
        WorldModel.HelperNode h=nearestHelper(155);if(h!=null){boolean fresh=core.claimHelperGift(h.index);announce(h.name,fresh?h.line+" Gift: "+h.gift:h.line,3.5f);if(fresh){audio.wizard();saveNow();}return;}
        WorldModel.WizardNode w=nearestWizard(175);if(w!=null){boolean before=core.isWizardMet(w.index),ready=core.meetWizard(w.index);if(ready){announce(w.name,w.line+" Rune: "+w.gift,4f);if(!before){audio.wizard();vibe(55);for(int i=0;i<35;i++)spawn(w.x,w.y-40,RAINBOW[i%6],1.7f);saveNow();}}else announce(w.name,"Bring "+(w.index<4?AlchemySystem.RECIPE_NAMES[w.index]:"the four guardian lessons")+". Keep exploring.",3f);return;}
        if(Math.abs(px-GameCore.HOME_X)<260){if(core.evaluateHome(px)){won=true;audio.home();saveNow();}else announce("EDEN COMMONS","Find Thoth just before the Commons.",2.2f);return;}
        announce("NAVI","Follow the luminous road. Forage what catches your eye.",1.8f);
    }

    private String contextLabel(){if(nearestResource(120)!=null)return "FORAGE";if(nearestCauldron(155)!=null)return "BREW";if(nearestHelper(155)!=null)return "HELLO";if(nearestWizard(175)!=null)return "LEARN";if(Math.abs(px-GameCore.HOME_X)<260)return "HOME";return "LOOK";}
    private WorldModel.ResourceNode nearestResource(float d){WorldModel.ResourceNode best=null;float bd=d*d;for(WorldModel.ResourceNode n:world.resources){if(n.gathered)continue;float dx=n.x-px,dy=n.y-py,v=dx*dx+dy*dy;if(v<bd){bd=v;best=n;}}return best;}
    private WorldModel.Cauldron nearestCauldron(float d){WorldModel.Cauldron best=null;float bd=d*d;for(WorldModel.Cauldron n:world.cauldrons){float dx=n.x-px,dy=n.y-py,v=dx*dx+dy*dy;if(v<bd){bd=v;best=n;}}return best;}
    private WorldModel.HelperNode nearestHelper(float d){WorldModel.HelperNode best=null;float bd=d*d;for(WorldModel.HelperNode n:world.helpers){float dx=n.x-px,dy=n.y-py,v=dx*dx+dy*dy;if(v<bd){bd=v;best=n;}}return best;}
    private WorldModel.WizardNode nearestWizard(float d){WorldModel.WizardNode best=null;float bd=d*d;for(WorldModel.WizardNode n:world.wizards){float dx=n.x-px,dy=n.y-py,v=dx*dx+dy*dy;if(v<bd){bd=v;best=n;}}return best;}
    private void announce(String who,String msg,float t){speaker=who;message=msg;messageT=t;}
    private void spawn(float x,float y,int color,float life){float a=rng.nextFloat()*(float)Math.PI*2,s=25+rng.nextFloat()*65;sparks.add(new Spark(x,y,(float)Math.cos(a)*s,(float)Math.sin(a)*s-20,life,2+rng.nextFloat()*4,color));}
    private void vibe(long ms){try{if(vibrator==null)return;if(Build.VERSION.SDK_INT>=26)vibrator.vibrate(VibrationEffect.createOneShot(ms,70));else vibrator.vibrate(ms);}catch(Exception ignored){}}
    private int zoneIndex(float x){for(int i=0;i<world.zones.length;i++)if(x>=world.zones[i].from&&x<world.zones[i].to)return i;return world.zones.length-1;}
    private int ingredientColor(int t){int[] c={0xff83e68b,0xff7fe6ee,0xffc995ff,0xffff745f,0xffffd65c,0xffffe37e,0xff63dce8};return c[Math.max(0,Math.min(c.length-1,t))];}
    private void drawWrapped(Canvas c,String s,float cx,float y,float width,float lh){String[] words=s.split(" ");StringBuilder line=new StringBuilder();float yy=y;for(String w:words){String test=line.length()==0?w:line+" "+w;if(text.measureText(test)>width&&line.length()>0){c.drawText(line.toString(),cx,yy,text);yy+=lh;line.setLength(0);line.append(w);}else{if(line.length()>0)line.append(' ');line.append(w);}}if(line.length()>0)c.drawText(line.toString(),cx,yy,text);}
}
