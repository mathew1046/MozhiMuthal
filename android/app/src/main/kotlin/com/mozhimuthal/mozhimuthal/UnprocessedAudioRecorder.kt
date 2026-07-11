package com.mozhimuthal.mozhimuthal

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.util.Log


class UnprocessedAudioRecorder {
    private var audioRecord: AudioRecord? = null
    val sampleRate = 16000
    val channelConfig = AudioFormat.CHANNEL_IN_MONO
    val audioFormat = AudioFormat.ENCODING_PCM_16BIT
    val minBuffer = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)
    var audioSourceUsed: String = "UNPROCESSED"

    fun startRecording(): Boolean {
        try {
            audioRecord = AudioRecord.Builder()
                .setAudioSource(MediaRecorder.AudioSource.UNPROCESSED)
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setSampleRate(sampleRate)
                        .setChannelMask(channelConfig)
                        .setEncoding(audioFormat)
                        .build()
                )
                .setBufferSizeInBytes(minBuffer * 4)
                .build()
            
            if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
                throw Exception("UNPROCESSED not supported")
            }
            audioSourceUsed = "UNPROCESSED"
        } catch (e: Exception) {
            Log.w("UnprocessedAudioRecorder", "UNPROCESSED failed, falling back to VOICE_RECOGNITION", e)
            audioRecord = AudioRecord.Builder()
                .setAudioSource(MediaRecorder.AudioSource.VOICE_RECOGNITION)
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setSampleRate(sampleRate)
                        .setChannelMask(channelConfig)
                        .setEncoding(audioFormat)
                        .build()
                )
                .setBufferSizeInBytes(minBuffer * 4)
                .build()
            audioSourceUsed = "VOICE_RECOGNITION"
        }

        if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
            Log.e("UnprocessedAudioRecorder", "ERR_MIC_LOCKED: AudioRecord initialization failed")
            return false
        }

        audioRecord?.startRecording()
        return true
    }

    fun read(buffer: ShortArray, offsetInShorts: Int, sizeInShorts: Int): Int {
        return audioRecord?.read(buffer, offsetInShorts, sizeInShorts) ?: 0
    }

    fun stopRecording() {
        if (audioRecord?.state == AudioRecord.STATE_INITIALIZED) {
            audioRecord?.stop()
        }
        audioRecord?.release()
        audioRecord = null
    }
}
