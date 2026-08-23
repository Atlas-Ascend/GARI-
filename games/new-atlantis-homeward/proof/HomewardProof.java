package com.ghostatlas.homeward;

public final class HomewardProof {
    private static void req(boolean v,String m){if(!v)throw new RuntimeException("PROOF_FAIL: "+m);}
    private static void forage(WorldModel w,GameCore c,float from,float to,int type,int needed){int n=0;for(WorldModel.ResourceNode r:w.resources){if(!r.gathered&&r.x>=from&&r.x<=to&&r.type==type&&n<needed){r.gathered=true;c.collect(type,1);n++;}}req(n==needed,"missing forage nodes type="+type+" need="+needed+" got="+n);}
    public static void main(String[] args){GameCore c=new GameCore();WorldModel w=new WorldModel();
        req(c.constrainX(GameCore.START_X,1800)<1720,"first bridge locked");
        forage(w,c,0,1720,GameCore.MOONLEAF,2);forage(w,c,0,1720,GameCore.CRYSTAL_REED,1);req(c.craft(GameCore.HORIZON_TEA),"Horizon Tea");req(c.meetWizard(0),"Sphinx");req(c.constrainX(1600,1800)>1720,"first bridge open");
        forage(w,c,0,3040,GameCore.STARSHROOM,2);forage(w,c,0,3040,GameCore.MOONLEAF,1);req(c.craft(GameCore.PASSAGE_TONIC),"Passage Tonic");req(c.meetWizard(1),"Anubis");req(c.constrainX(2900,3200)>3040,"second bridge open");
        forage(w,c,3040,4300,GameCore.EMBERBERRY,2);forage(w,c,3040,4300,GameCore.CRYSTAL_REED,1);req(c.craft(GameCore.BLESSING_OIL),"Blessing Oil");req(c.meetWizard(2),"Hamsa");req(c.constrainX(4200,4400)>4300,"third bridge open");
        forage(w,c,4300,5520,GameCore.PRISM_SEED,1);forage(w,c,4300,5520,GameCore.STARSHROOM,1);forage(w,c,4300,5520,GameCore.EMBERBERRY,1);req(c.craft(GameCore.RAINBOW_ELIXIR),"Rainbow Elixir");req(c.meetWizard(3),"Oracle");req(c.constrainX(5400,5650)>5520,"fourth bridge open");
        req(c.meetWizard(4),"Thoth");req(c.evaluateHome(GameCore.HOME_X),"reach tribe");
        System.out.println("HOMEWARD_PROOF_OK");System.out.println("objective=GET_HOME_TO_THE_TRIBE");System.out.println("foraged="+c.getForageCount());System.out.println("brews="+c.getCraftCount());System.out.println("wizards="+c.wizardCount());System.out.println("won="+c.isWon());}
}
