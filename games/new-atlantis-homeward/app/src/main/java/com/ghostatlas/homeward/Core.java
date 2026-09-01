package com.ghostatlas.homeward;

import java.util.ArrayList;
import java.util.Arrays;

final class Inventory {
    static final String[] NAMES={"Moonleaf","Crystal Reed","Starshroom","Emberberry","Prism Seed"};
}

final class AlchemySystem {
    static final String[] RECIPE_NAMES={"Horizon Tea","Passage Tonic","Blessing Oil","Rainbow Elixir"};
    static final String[] RECIPE_DESC={"2 Moonleaf + 1 Crystal Reed","2 Starshroom + 1 Moonleaf","2 Emberberry + 1 Crystal Reed","1 Prism Seed + 1 Starshroom + 1 Emberberry"};
}

final class GameCore {
    static final int MOONLEAF=0,CRYSTAL_REED=1,STARSHROOM=2,EMBERBERRY=3,PRISM_SEED=4,INGREDIENT_COUNT=5;
    static final int HORIZON_TEA=0,PASSAGE_TONIC=1,BLESSING_OIL=2,RAINBOW_ELIXIR=3,RECIPE_COUNT=4;
    static final float WORLD_W=6900f,START_X=160f,HOME_X=6420f;
    private final int[] ingredients=new int[INGREDIENT_COUNT];
    private final boolean[] crafted=new boolean[RECIPE_COUNT];
    private final boolean[] wizard=new boolean[5];
    private int forageCount,craftCount;
    private boolean won;

    void collect(int ingredient,int amount){if(ingredient>=0&&ingredient<INGREDIENT_COUNT&&amount>0){ingredients[ingredient]+=amount;forageCount+=amount;}}
    void gather(int ingredient,int amount){collect(ingredient,amount);}
    boolean canCraft(int r){switch(r){
        case HORIZON_TEA:return ingredients[MOONLEAF]>=2&&ingredients[CRYSTAL_REED]>=1;
        case PASSAGE_TONIC:return ingredients[STARSHROOM]>=2&&ingredients[MOONLEAF]>=1;
        case BLESSING_OIL:return ingredients[EMBERBERRY]>=2&&ingredients[CRYSTAL_REED]>=1;
        case RAINBOW_ELIXIR:return ingredients[PRISM_SEED]>=1&&ingredients[STARSHROOM]>=1&&ingredients[EMBERBERRY]>=1;
        default:return false;}}
    boolean craft(int r){if(r<0||r>=RECIPE_COUNT||crafted[r]||!canCraft(r))return false;switch(r){
        case HORIZON_TEA:ingredients[MOONLEAF]-=2;ingredients[CRYSTAL_REED]--;break;
        case PASSAGE_TONIC:ingredients[STARSHROOM]-=2;ingredients[MOONLEAF]--;break;
        case BLESSING_OIL:ingredients[EMBERBERRY]-=2;ingredients[CRYSTAL_REED]--;break;
        case RAINBOW_ELIXIR:ingredients[PRISM_SEED]--;ingredients[STARSHROOM]--;ingredients[EMBERBERRY]--;break;}
        crafted[r]=true;craftCount++;return true;}
    boolean meetWizard(int i){if(i<0||i>=5)return false;if(wizard[i])return true;boolean ready=i==0?crafted[0]:i==1?crafted[1]:i==2?crafted[2]:i==3?crafted[3]:wizard[0]&&wizard[1]&&wizard[2]&&wizard[3];if(ready)wizard[i]=true;return ready;}
    float constrainX(float oldX,float proposed){float x=Math.max(80f,Math.min(WORLD_W-80f,proposed));float[] gates={1720f,3040f,4300f,5520f};for(int i=0;i<4;i++)if(!wizard[i]&&oldX<=gates[i]&&x>gates[i])return gates[i]-34f;return x;}
    boolean evaluateHome(float x){won=x>=HOME_X&&wizard[4];return won;}
    int getIngredient(int i){return ingredients[i];} boolean isCrafted(int i){return crafted[i];} boolean isWizardMet(int i){return wizard[i];}
    int getForageCount(){return forageCount;} int getCraftCount(){return craftCount;} boolean isWon(){return won;}
    int wizardCount(){int n=0;for(boolean b:wizard)if(b)n++;return n;} String inventoryProof(){return Arrays.toString(ingredients);}
    void reset(){Arrays.fill(ingredients,0);Arrays.fill(crafted,false);Arrays.fill(wizard,false);forageCount=craftCount=0;won=false;}
}

final class WorldModel {
    static final class ResourceNode { final float x,y; final int type; boolean gathered; ResourceNode(float x,float y,int type){this.x=x;this.y=y;this.type=type;} }
    static final class WizardNode { final float x,y; final int index; final String name,line,gift; WizardNode(float x,float y,int index,String name,String line,String gift){this.x=x;this.y=y;this.index=index;this.name=name;this.line=line;this.gift=gift;} }
    static final class Cauldron { final float x,y; Cauldron(float x,float y){this.x=x;this.y=y;} }
    final ArrayList<ResourceNode> resources=new ArrayList<>();
    final ArrayList<WizardNode> wizards=new ArrayList<>();
    final ArrayList<Cauldron> cauldrons=new ArrayList<>();
    WorldModel(){
        add(GameCore.MOONLEAF,380,350);add(GameCore.MOONLEAF,610,700);add(GameCore.MOONLEAF,910,275);add(GameCore.MOONLEAF,1330,760);
        add(GameCore.CRYSTAL_REED,530,530);add(GameCore.CRYSTAL_REED,1180,520);add(GameCore.CRYSTAL_REED,1500,340);cauldrons.add(new Cauldron(1420,560));
        wizards.add(new WizardNode(1580,430,0,"SPHINX WIZARD","Taste the horizon. Let the road show you its next shape.","AKHET SIGHT"));
        add(GameCore.STARSHROOM,1910,300);add(GameCore.STARSHROOM,2190,690);add(GameCore.STARSHROOM,2500,410);add(GameCore.MOONLEAF,2750,750);cauldrons.add(new Cauldron(2760,470));
        wizards.add(new WizardNode(2920,620,1,"ANUBIS, KEEPER OF PASSAGE","Every threshold can become a doorway when you carry yourself whole.","PASSAGE STEP"));
        add(GameCore.EMBERBERRY,3260,300);add(GameCore.EMBERBERRY,3510,690);add(GameCore.EMBERBERRY,3790,390);add(GameCore.CRYSTAL_REED,4050,720);cauldrons.add(new Cauldron(4020,490));
        wizards.add(new WizardNode(4180,390,2,"HAMSA WITCH","An open hand can protect, receive, bless, and share at the same time.","BLESSING FIELD"));
        add(GameCore.PRISM_SEED,4550,520);add(GameCore.STARSHROOM,4740,280);add(GameCore.EMBERBERRY,5000,720);cauldrons.add(new Cauldron(5180,500));
        wizards.add(new WizardNode(5380,660,3,"RAINBOW ORACLE","Many realities can bloom without your center disappearing.","RAINBOW BODY"));
        wizards.add(new WizardNode(5950,400,4,"THOTH OF NEW ATLANTIS","You gathered the road into memory. Now walk the last light home.","THOTH MEMORY"));
    }
    private void add(int t,float x,float y){resources.add(new ResourceNode(x,y,t));}
}
