package com.mozhimuthal.mozhimuthal

import android.content.Context
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.util.Log
import java.io.BufferedInputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.util.concurrent.Executors


class UnprocessedAudioRecorder(private val context: Context) {
    private var audioRecord: AudioRecord? = null
    val sampleRate = 16000
    val channelConfig = AudioFormat.CHANNEL_IN_MONO
    val audioFormat = AudioFormat.ENCODING_PCM_16BIT
    private val minBuffer = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)
    var audioSourceUsed: String = "UNPROCESSED"
    private var temporaryRecording: File? = null
    private var recordingOutput: FileOutputStream? = null

    fun startRecording(): Boolean {
        deleteTemporaryRecording()
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
        temporaryRecording = File(context.cacheDir, "screening-recording.pcm")
        recordingOutput = FileOutputStream(temporaryRecording)
        return true
    }

    fun read(buffer: ShortArray, offsetInShorts: Int, sizeInShorts: Int): Int {
        return audioRecord?.read(buffer, offsetInShorts, sizeInShorts) ?: 0
    }

    /** Saves only a short-lived, local PCM copy so the worker can review it. */
    fun appendToTemporaryRecording(samples: ShortArray, count: Int) {
        val bytes = ByteArray(count * 2)
        for (i in 0 until count) {
            val value = samples[i].toInt()
            bytes[i * 2] = (value and 0xff).toByte()
            bytes[i * 2 + 1] = ((value shr 8) and 0xff).toByte()
        }
        recordingOutput?.write(bytes)
    }

    fun stopRecording() {
        try {
            if (audioRecord?.state == AudioRecord.STATE_INITIALIZED) {
                audioRecord?.stop()
            }
        } catch (e: IllegalStateException) {
            Log.w("UnprocessedAudioRecorder", "AudioRecord was already stopped", e)
        } finally {
            audioRecord?.release()
            audioRecord = null
            recordingOutput?.flush()
            recordingOutput?.close()
            recordingOutput = null
        }
    }

    fun hasTemporaryRecording(): Boolean {
        val file = temporaryRecording
        return file != null && file.exists() && file.length() > 0
    }

    /** Playback is intentionally one-shot: the PCM file is deleted when it ends. */
    fun replayAndDelete(onFinished: () -> Unit) {
        val file = temporaryRecording
        if (file == null || !file.exists()) throw IllegalStateException("No recording available to replay")
        Executors.newSingleThreadExecutor().execute {
            val minBuffer = AudioTrack.getMinBufferSize(sampleRate, AudioFormat.CHANNEL_OUT_MONO, audioFormat)
            val track = AudioTrack(
                android.media.AudioManager.STREAM_MUSIC,
                sampleRate,
                AudioFormat.CHANNEL_OUT_MONO,
                audioFormat,
                minBuffer.coerceAtLeast(4096),
                AudioTrack.MODE_STREAM,
            )
            try {
                track.play()
                BufferedInputStream(FileInputStream(file)).use { input ->
                    val buffer = ByteArray(4096)
                    while (true) {
                        val count = input.read(buffer)
                        if (count <= 0) break
                        track.write(buffer, 0, count)
                    }
                }
                Thread.sleep(150)
            } finally {
                track.stop()
                track.release()
                deleteTemporaryRecording()
                onFinished()
            }
        }
    }

    fun deleteTemporaryRecording() {
        recordingOutput?.close()
        recordingOutput = null
        temporaryRecording?.delete()
        temporaryRecording = null
    }
}
