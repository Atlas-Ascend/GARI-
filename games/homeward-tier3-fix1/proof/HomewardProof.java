package com.ghostatlas.homeward;

public final class HomewardProof {
    private static void req(boolean v,String m){if(!v)throw new RuntimeException("PROOF_FAIL: "+m);}
    private static void forage(WorldModel w,GameCore c,float from,float to,int type,int needed){
        int n=0;
        for(WorldModel.ResourceNode r:w.resources){
            if(!r.gathered&&r.x>=from&&r.x<=to&&r.type==type&&n<needed){r.gathered=true;c.collect(type,1);n++;}
        }
        req(n==needed,"missing forage nodes type="+type+" need="+needed+" got="+n);
    }
    public static void main(String[] args){
        GameCore c=new GameCore();WorldModel w=new WorldModel();
        req(c.constrainX(GameCore.START_X,1800)<1760,"first bridge locked");
        forage(w,c,0,1760,GameCore.MOONLEAF,3);
        forage(w,c,0,1760,GameCore.CRYSTAL_REED,2);
        forage(w,c,0,1760,GameCore.SUNMINT,1);
        req(c.craft(GameCore.HORIZON_TEA),"Horizon Tea");
        req(c.craft(GameCore.STARLIGHT_SOUP),"Starlight Soup");
        req(c.meetWizard(0),"Sphinx");
        req(c.claimHelperGift(0),"Mara helper");
        req(c.constrainX(1600,1820)>1760,"first bridge open");

        forage(w,c,1760,3140,GameCore.STARSHROOM,2);
        forage(w,c,1760,3140,GameCore.MOONLEAF,1);
        req(c.craft(GameCore.PASSAGE_TONIC),"Passage Tonic");
        req(c.meetWizard(1),"Anubis");
        req(c.claimHelperGift(1),"Ione helper");
        req(c.constrainX(3000,3200)>3140,"second bridge open");

        forage(w,c,3140,4460,GameCore.EMBERBERRY,2);
        forage(w,c,3140,4460,GameCore.CRYSTAL_REED,1);
        req(c.craft(GameCore.BLESSING_OIL),"Blessing Oil");
        req(c.meetWizard(2),"Hamsa");
        req(c.claimHelperGift(2),"Sol helper");
        req(c.constrainX(4300,4520)>4460,"third bridge open");

        forage(w,c,4460,5740,GameCore.PRISM_SEED,2);
        forage(w,c,4460,5740,GameCore.STARSHROOM,1);
        forage(w,c,4460,5740,GameCore.EMBERBERRY,2);
        forage(w,c,4460,5740,GameCore.TIDEGLASS,1);
        req(c.craft(GameCore.RAINBOW_ELIXIR),"Rainbow Elixir");
        req(c.craft(GameCore.HOMEFIRE_INCENSE),"Homefire Incense");
        req(c.meetWizard(3),"Oracle");
        req(c.claimHelperGift(3),"Navi helper");
        req(c.constrainX(5600,5800)>5740,"fourth bridge open");

        req(c.meetWizard(4),"Thoth");
        req(c.evaluateHome(GameCore.HOME_X),"reach tribe");
        req(c.isWon(),"won flag");
        System.out.println("HOMEWARD_TIER3_PROOF_OK");
        System.out.println("objective=GET_HOME_TO_THE_TRIBE");
        System.out.println("foraged="+c.getForageCount());
        System.out.println("brews="+c.getCraftCount());
        System.out.println("wizards="+c.wizardCount());
        System.out.println("helpers="+c.helperCount());
        System.out.println("optional_alchemy=2");
        System.out.println("won="+c.isWon());
    }
}
