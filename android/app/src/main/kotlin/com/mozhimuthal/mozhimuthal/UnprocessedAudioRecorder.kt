package com.mozhimuthal.mozhimuthal

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder

class UnprocessedAudioRecorder {
    private var audioRecord: AudioRecord? = null
    val sampleRate = 16000
    val channelConfig = AudioFormat.CHANNEL_IN_MONO
    val audioFormat = AudioFormat.ENCODING_PCM_16BIT
    val minBuffer = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)

    fun startRecording() {
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
        audioRecord?.startRecording()
    }

    fun read(buffer: ShortArray, offsetInShorts: Int, sizeInShorts: Int): Int {
        return audioRecord?.read(buffer, offsetInShorts, sizeInShorts) ?: 0
    }

    fun stopRecording() {
        audioRecord?.stop()
        audioRecord?.release()
        audioRecord = null
    }
}
