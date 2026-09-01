package com.ghostatlas.homeward;

import android.content.Context;
import android.content.SharedPreferences;

final class SaveSystem {
    private static final String FILE="homeward_tier3_save";
    private final SharedPreferences p;
    SaveSystem(Context c){p=c.getSharedPreferences(FILE,Context.MODE_PRIVATE);}
    boolean hasSave(){return p.getBoolean("present",false);}
    float loadX(){return p.getFloat("x",GameCore.START_X);}
    void load(GameCore c,WorldModel w){
        if(!hasSave())return;
        c.restore(
            ints(p.getString("inv",""),GameCore.INGREDIENT_COUNT),
            bools(p.getString("craft",""),GameCore.RECIPE_COUNT),
            bools(p.getString("wiz",""),GameCore.WIZARD_COUNT),
            bools(p.getString("help",""),GameCore.HELPER_COUNT),
            p.getInt("forage",0),p.getInt("crafts",0),p.getBoolean("won",false)
        );
        String g=p.getString("gathered","");
        if(g!=null&&!g.isEmpty()){
            String[] parts=g.split(",");
            for(String s:parts)try{
                int id=Integer.parseInt(s);
                for(WorldModel.ResourceNode n:w.resources)if(n.id==id){n.gathered=true;break;}
            }catch(Exception ignored){}
        }
    }
    void save(GameCore c,WorldModel w,float x){
        StringBuilder g=new StringBuilder();
        for(WorldModel.ResourceNode n:w.resources)if(n.gathered){if(g.length()>0)g.append(',');g.append(n.id);}
        p.edit().putBoolean("present",true).putFloat("x",x)
            .putString("inv",join(c.ingredientsCopy())).putString("craft",join(c.craftedCopy()))
            .putString("wiz",join(c.wizardCopy())).putString("help",join(c.helperCopy()))
            .putInt("forage",c.getForageCount()).putInt("crafts",c.getCraftCount())
            .putBoolean("won",c.isWon()).putString("gathered",g.toString()).apply();
    }
    void clear(){p.edit().clear().apply();}
    private static String join(int[] a){StringBuilder b=new StringBuilder();for(int i=0;i<a.length;i++){if(i>0)b.append(',');b.append(a[i]);}return b.toString();}
    private static String join(boolean[] a){StringBuilder b=new StringBuilder();for(int i=0;i<a.length;i++){if(i>0)b.append(',');b.append(a[i]?'1':'0');}return b.toString();}
    private static int[] ints(String s,int n){int[] a=new int[n];if(s==null||s.isEmpty())return a;String[] q=s.split(",");for(int i=0;i<Math.min(n,q.length);i++)try{a[i]=Integer.parseInt(q[i]);}catch(Exception ignored){}return a;}
    private static boolean[] bools(String s,int n){boolean[] a=new boolean[n];if(s==null||s.isEmpty())return a;String[] q=s.split(",");for(int i=0;i<Math.min(n,q.length);i++)a[i]="1".equals(q[i]);return a;}
}
