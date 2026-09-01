package com.ghostatlas.homeward;

import java.util.ArrayList;
import java.util.Arrays;

final class Inventory {
    static final String[] NAMES={"Moonleaf","Crystal Reed","Starshroom","Emberberry","Prism Seed","Sunmint","Tideglass"};
    static final String[] SHORT={"MOON","REED","STAR","EMBER","PRISM","SUN","TIDE"};
}

final class AlchemySystem {
    static final String[] RECIPE_NAMES={"Horizon Tea","Passage Tonic","Blessing Oil","Rainbow Elixir","Starlight Soup","Homefire Incense"};
    static final String[] RECIPE_DESC={
        "2 Moonleaf + 1 Crystal Reed",
        "2 Starshroom + 1 Moonleaf",
        "2 Emberberry + 1 Crystal Reed",
        "1 Prism Seed + 1 Starshroom + 1 Emberberry",
        "1 Sunmint + 1 Crystal Reed + 1 Moonleaf",
        "1 Tideglass + 1 Emberberry + 1 Prism Seed"
    };
}

final class GameCore {
    static final int MOONLEAF=0,CRYSTAL_REED=1,STARSHROOM=2,EMBERBERRY=3,PRISM_SEED=4,SUNMINT=5,TIDEGLASS=6,INGREDIENT_COUNT=7;
    static final int HORIZON_TEA=0,PASSAGE_TONIC=1,BLESSING_OIL=2,RAINBOW_ELIXIR=3,STARLIGHT_SOUP=4,HOMEFIRE_INCENSE=5,RECIPE_COUNT=6;
    static final int WIZARD_COUNT=5,HELPER_COUNT=4;
    static final float WORLD_W=7200f,START_X=160f,HOME_X=6660f;
    private final int[] ingredients=new int[INGREDIENT_COUNT];
    private final boolean[] crafted=new boolean[RECIPE_COUNT];
    private final boolean[] wizard=new boolean[WIZARD_COUNT];
    private final boolean[] helper=new boolean[HELPER_COUNT];
    private int forageCount,craftCount;
    private boolean won;

    void collect(int ingredient,int amount){if(ingredient>=0&&ingredient<INGREDIENT_COUNT&&amount>0){ingredients[ingredient]+=amount;forageCount+=amount;}}
    void gather(int ingredient,int amount){collect(ingredient,amount);}
    boolean canCraft(int r){switch(r){
        case HORIZON_TEA:return ingredients[MOONLEAF]>=2&&ingredients[CRYSTAL_REED]>=1;
        case PASSAGE_TONIC:return ingredients[STARSHROOM]>=2&&ingredients[MOONLEAF]>=1;
        case BLESSING_OIL:return ingredients[EMBERBERRY]>=2&&ingredients[CRYSTAL_REED]>=1;
        case RAINBOW_ELIXIR:return ingredients[PRISM_SEED]>=1&&ingredients[STARSHROOM]>=1&&ingredients[EMBERBERRY]>=1;
        case STARLIGHT_SOUP:return ingredients[SUNMINT]>=1&&ingredients[CRYSTAL_REED]>=1&&ingredients[MOONLEAF]>=1;
        case HOMEFIRE_INCENSE:return ingredients[TIDEGLASS]>=1&&ingredients[EMBERBERRY]>=1&&ingredients[PRISM_SEED]>=1;
        default:return false;}}
    boolean craft(int r){
        if(r<0||r>=RECIPE_COUNT||crafted[r]||!canCraft(r))return false;
        switch(r){
            case HORIZON_TEA:ingredients[MOONLEAF]-=2;ingredients[CRYSTAL_REED]--;break;
            case PASSAGE_TONIC:ingredients[STARSHROOM]-=2;ingredients[MOONLEAF]--;break;
            case BLESSING_OIL:ingredients[EMBERBERRY]-=2;ingredients[CRYSTAL_REED]--;break;
            case RAINBOW_ELIXIR:ingredients[PRISM_SEED]--;ingredients[STARSHROOM]--;ingredients[EMBERBERRY]--;break;
            case STARLIGHT_SOUP:ingredients[SUNMINT]--;ingredients[CRYSTAL_REED]--;ingredients[MOONLEAF]--;break;
            case HOMEFIRE_INCENSE:ingredients[TIDEGLASS]--;ingredients[EMBERBERRY]--;ingredients[PRISM_SEED]--;break;
        }
        crafted[r]=true;craftCount++;return true;
    }
    boolean meetWizard(int i){
        if(i<0||i>=WIZARD_COUNT)return false;
        if(wizard[i])return true;
        boolean ready=i==0?crafted[HORIZON_TEA]:
            i==1?crafted[PASSAGE_TONIC]:
            i==2?crafted[BLESSING_OIL]:
            i==3?crafted[RAINBOW_ELIXIR]:
            wizard[0]&&wizard[1]&&wizard[2]&&wizard[3];
        if(ready)wizard[i]=true;
        return ready;
    }
    boolean claimHelperGift(int i){
        if(i<0||i>=HELPER_COUNT||helper[i])return false;
        helper[i]=true;
        switch(i){
            case 0: collect(SUNMINT,1);collect(MOONLEAF,1);break;
            case 1: collect(TIDEGLASS,1);collect(CRYSTAL_REED,1);break;
            case 2: collect(EMBERBERRY,1);collect(STARSHROOM,1);break;
            case 3: collect(PRISM_SEED,1);break;
        }
        return true;
    }
    float constrainX(float oldX,float proposed){
        float x=Math.max(80f,Math.min(WORLD_W-80f,proposed));
        float[] gates={1760f,3140f,4460f,5740f};
        for(int i=0;i<4;i++)if(!wizard[i]&&oldX<=gates[i]&&x>gates[i])return gates[i]-34f;
        return x;
    }
    boolean evaluateHome(float x){won=x>=HOME_X&&wizard[4];return won;}
    int getIngredient(int i){return ingredients[i];}
    boolean isCrafted(int i){return crafted[i];}
    boolean isWizardMet(int i){return wizard[i];}
    boolean isHelperMet(int i){return helper[i];}
    int getForageCount(){return forageCount;}
    int getCraftCount(){return craftCount;}
    boolean isWon(){return won;}
    int wizardCount(){int n=0;for(boolean b:wizard)if(b)n++;return n;}
    int helperCount(){int n=0;for(boolean b:helper)if(b)n++;return n;}
    String inventoryProof(){return Arrays.toString(ingredients);}
    int[] ingredientsCopy(){return Arrays.copyOf(ingredients,ingredients.length);}
    boolean[] craftedCopy(){return Arrays.copyOf(crafted,crafted.length);}
    boolean[] wizardCopy(){return Arrays.copyOf(wizard,wizard.length);}
    boolean[] helperCopy(){return Arrays.copyOf(helper,helper.length);}
    void restore(int[] inv,boolean[] craft,boolean[] wiz,boolean[] help,int forage,int crafts,boolean victory){
        Arrays.fill(ingredients,0);Arrays.fill(crafted,false);Arrays.fill(wizard,false);Arrays.fill(helper,false);
        if(inv!=null)System.arraycopy(inv,0,ingredients,0,Math.min(inv.length,ingredients.length));
        if(craft!=null)System.arraycopy(craft,0,crafted,0,Math.min(craft.length,crafted.length));
        if(wiz!=null)System.arraycopy(wiz,0,wizard,0,Math.min(wiz.length,wizard.length));
        if(help!=null)System.arraycopy(help,0,helper,0,Math.min(help.length,helper.length));
        forageCount=Math.max(0,forage);craftCount=Math.max(0,crafts);won=victory;
    }
    void reset(){Arrays.fill(ingredients,0);Arrays.fill(crafted,false);Arrays.fill(wizard,false);Arrays.fill(helper,false);forageCount=craftCount=0;won=false;}
}

final class WorldModel {
    static final class Zone {
        final float from,to; final String name,subtitle;
        Zone(float from,float to,String name,String subtitle){this.from=from;this.to=to;this.name=name;this.subtitle=subtitle;}
    }
    static final class ResourceNode {
        final int id,type,rarity; final float x,y; boolean gathered;
        ResourceNode(int id,float x,float y,int type,int rarity){this.id=id;this.x=x;this.y=y;this.type=type;this.rarity=rarity;}
    }
    static final class WizardNode {
        final float x,y; final int index; final String name,line,gift;
        WizardNode(float x,float y,int index,String name,String line,String gift){this.x=x;this.y=y;this.index=index;this.name=name;this.line=line;this.gift=gift;}
    }
    static final class HelperNode {
        final float x,y; final int index; final String name,line,gift;
        HelperNode(float x,float y,int index,String name,String line,String gift){this.x=x;this.y=y;this.index=index;this.name=name;this.line=line;this.gift=gift;}
    }
    static final class Cauldron { final float x,y; Cauldron(float x,float y){this.x=x;this.y=y;} }

    final ArrayList<ResourceNode> resources=new ArrayList<>();
    final ArrayList<WizardNode> wizards=new ArrayList<>();
    final ArrayList<HelperNode> helpers=new ArrayList<>();
    final ArrayList<Cauldron> cauldrons=new ArrayList<>();
    final Zone[] zones={
        new Zone(0,1760,"AKHET GARDENS","moonleaf terraces • crystal canals"),
        new Zone(1760,3140,"PASSAGE WOODS","starshroom groves • lantern paths"),
        new Zone(3140,4460,"HAMSA MARKET","ember orchards • blessing stalls"),
        new Zone(4460,5740,"PRISM COAST","tideglass pools • rainbow reefs"),
        new Zone(5740,7200,"EDEN APPROACH","homefire road • commons skyline")
    };
    private int nextId=0;

    WorldModel(){
        // Zone 1
        add(GameCore.MOONLEAF,360,360,1);add(GameCore.MOONLEAF,610,710,1);add(GameCore.MOONLEAF,900,300,1);add(GameCore.MOONLEAF,1260,745,1);add(GameCore.MOONLEAF,1480,420,2);
        add(GameCore.CRYSTAL_REED,510,530,1);add(GameCore.CRYSTAL_REED,1080,540,1);add(GameCore.CRYSTAL_REED,1510,335,2);
        add(GameCore.SUNMINT,760,450,2);add(GameCore.SUNMINT,1360,600,2);
        helpers.add(new HelperNode(1040,700,0,"MARA • FORAGER","The garden gives more when you notice what grows between destinations.","SUNMINT + MOONLEAF"));
        cauldrons.add(new Cauldron(1490,575));
        wizards.add(new WizardNode(1630,420,0,"SPHINX WIZARD","Taste the horizon. Let the road show you its next shape.","AKHET SIGHT"));

        // Zone 2
        add(GameCore.STARSHROOM,1930,310,1);add(GameCore.STARSHROOM,2180,690,1);add(GameCore.STARSHROOM,2490,420,1);add(GameCore.STARSHROOM,2850,320,2);
        add(GameCore.MOONLEAF,2730,740,1);add(GameCore.MOONLEAF,2060,530,1);
        add(GameCore.TIDEGLASS,2350,560,2);add(GameCore.TIDEGLASS,2940,710,2);
        helpers.add(new HelperNode(2320,370,1,"IONE • TIDE GARDENER","Carry a little water from every shore. It remembers how to become a path.","TIDEGLASS + CRYSTAL REED"));
        cauldrons.add(new Cauldron(2860,500));
        wizards.add(new WizardNode(3020,620,1,"ANUBIS • KEEPER OF PASSAGE","Every threshold can become a doorway when you carry yourself whole.","PASSAGE STEP"));

        // Zone 3
        add(GameCore.EMBERBERRY,3280,310,1);add(GameCore.EMBERBERRY,3520,690,1);add(GameCore.EMBERBERRY,3820,390,1);add(GameCore.EMBERBERRY,4140,720,2);
        add(GameCore.CRYSTAL_REED,4050,520,1);add(GameCore.CRYSTAL_REED,3360,565,1);
        add(GameCore.SUNMINT,3720,600,2);
        helpers.add(new HelperNode(3650,300,2,"SOL • COMMONS COOK","Good alchemy feeds somebody. Take enough to share when the road gets long.","EMBERBERRY + STARSHROOM"));
        cauldrons.add(new Cauldron(4160,500));
        wizards.add(new WizardNode(4340,390,2,"HAMSA WITCH","An open hand can protect, receive, bless, and share at the same time.","BLESSING FIELD"));

        // Zone 4
        add(GameCore.PRISM_SEED,4620,520,2);add(GameCore.PRISM_SEED,5350,300,3);
        add(GameCore.STARSHROOM,4840,285,1);add(GameCore.STARSHROOM,5200,690,1);
        add(GameCore.EMBERBERRY,5010,720,1);add(GameCore.EMBERBERRY,5480,520,1);
        add(GameCore.TIDEGLASS,4760,665,2);add(GameCore.TIDEGLASS,5560,350,2);
        helpers.add(new HelperNode(5050,410,3,"NAVI • WAYFINDER","The shortest route home is the one that keeps wonder alive.","PRISM SEED"));
        cauldrons.add(new Cauldron(5480,500));
        wizards.add(new WizardNode(5620,660,3,"RAINBOW ORACLE","Many realities can bloom without your center disappearing.","RAINBOW BODY"));

        // Zone 5
        wizards.add(new WizardNode(6190,410,4,"THOTH OF NEW ATLANTIS","You gathered the road into memory. Now walk the last light home.","THOTH MEMORY"));
    }
    Zone zoneFor(float x){for(Zone z:zones)if(x>=z.from&&x<z.to)return z;return zones[zones.length-1];}
    private void add(int t,float x,float y,int rarity){resources.add(new ResourceNode(nextId++,x,y,t,rarity));}
}
