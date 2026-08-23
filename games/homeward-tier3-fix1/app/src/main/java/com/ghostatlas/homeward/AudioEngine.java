package com.ghostatlas.homeward;

import android.media.AudioAttributes;
import android.media.AudioFormat;
import android.media.AudioTrack;
import android.media.ToneGenerator;
import android.media.AudioManager;

final class AudioEngine {
    private AudioTrack ambient;
    private final ToneGenerator tone=new ToneGenerator(AudioManager.STREAM_MUSIC,38);
    AudioEngine(){buildAmbient();}
    private void buildAmbient(){
        try{
            final int sr=22050, seconds=4, frames=sr*seconds;
            short[] pcm=new short[frames*2];
            for(int i=0;i<frames;i++){
                double t=i/(double)sr;
                double swell=.55+.45*Math.sin(2*Math.PI*.08*t);
                double a=Math.sin(2*Math.PI*110*t)*.22;
                double b=Math.sin(2*Math.PI*165*t)*.12;
                double c=Math.sin(2*Math.PI*220*t)*.06;
                short v=(short)(32767*(a+b+c)*swell*.24);
                pcm[i*2]=v;pcm[i*2+1]=v;
            }
            AudioAttributes at=new AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_GAME).setContentType(AudioAttributes.CONTENT_TYPE_MUSIC).build();
            AudioFormat fm=new AudioFormat.Builder().setEncoding(AudioFormat.ENCODING_PCM_16BIT).setSampleRate(sr).setChannelMask(AudioFormat.CHANNEL_OUT_STEREO).build();
            ambient=new AudioTrack.Builder().setAudioAttributes(at).setAudioFormat(fm).setBufferSizeInBytes(pcm.length*2).setTransferMode(AudioTrack.MODE_STATIC).build();
            ambient.write(pcm,0,pcm.length);ambient.setLoopPoints(0,frames,-1);ambient.setVolume(.16f);
        }catch(Exception ignored){ambient=null;}
    }
    void start(){try{if(ambient!=null&&ambient.getPlayState()!=AudioTrack.PLAYSTATE_PLAYING)ambient.play();}catch(Exception ignored){}}
    void pause(){try{if(ambient!=null)ambient.pause();}catch(Exception ignored){}}
    void stop(){try{if(ambient!=null){ambient.stop();ambient.release();}}catch(Exception ignored){}try{tone.release();}catch(Exception ignored){}}
    void gather(){tone.startTone(ToneGenerator.TONE_PROP_BEEP,70);}
    void brew(){tone.startTone(ToneGenerator.TONE_DTMF_9,130);}
    void wizard(){tone.startTone(ToneGenerator.TONE_SUP_RINGTONE,260);}
    void gate(){tone.startTone(ToneGenerator.TONE_PROP_ACK,150);}
    void home(){tone.startTone(ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD,500);}
}
