import openai
import json
from dotenv import load_dotenv
import os

load_dotenv()
api_key = os.getenv('OPENAI_API_KEY')
client = openai.OpenAI(api_key=api_key)


# 音声ファイルのパス
audio_path = "/Users/kikuyama/shadow_speak_v2/assets/audio/introduction.wav"

# 文字起こし（タイムスタンプ付き）
with open(audio_path, "rb") as audio_file:
    print("📤 タイムスタンプ付きで文字起こし中...")
    response = client.audio.transcriptions.create(
        model="whisper-1",
        file=audio_file,
        response_format="verbose_json"  # ← word_timestamps は削除（API未対応なので）
    )

    # JSONデータを辞書化
    full_data = response.model_dump()

    # 📄 segments だけ抽出して Flutter 用 JSON に整形
    segments = [
        {
            "start": round(seg["start"], 2),
            "end": round(seg["end"], 2),
            "text": seg["text"].strip()
        }
        for seg in full_data.get("segments", [])
    ]

    # ファイルに保存
    with open("subtitle_segments.json", "w") as out_file:
        json.dump(segments, out_file, indent=2)

    print("✅ 字幕ファイル subtitle_segments.json を保存しました。")