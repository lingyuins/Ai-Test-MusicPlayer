from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
import os
import sys
import json
from mutagen import File as MutagenFile
import mutagen.id3
import mutagen.mp4
import mutagen.flac
import mutagen.oggvorbis
import mutagen.wavpack
import shutil
import random
from typing import List, Dict, Any
from pathlib import Path

app = FastAPI()

# 允许CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 支持的音频格式
supported_formats = ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a', '.wma']

# 配置文件路径
config_path = Path('config.json')

# 初始化配置
def init_config():
    if not config_path.exists():
        default_config = {
            "music_folders": [],
            "playlists": {},
            "current_playlist": "",
            "current_song": 0,
            "play_mode": "order",  # order, repeat, shuffle
            "volume": 0.7,
            "equalizer": "normal",
            "dark_theme": False,
            "view_style": "list",
            "scan_history": []
        }
        with open(config_path, 'w', encoding='utf-8') as f:
            json.dump(default_config, f, ensure_ascii=False, indent=2)
    with open(config_path, 'r', encoding='utf-8') as f:
        return json.load(f)

# 保存配置
def save_config(config):
    with open(config_path, 'w', encoding='utf-8') as f:
        json.dump(config, f, ensure_ascii=False, indent=2)

config = init_config()

# 扫描音乐文件
def scan_music_files(folder_path: str) -> List[Dict[str, Any]]:
    music_files = []
    for root, dirs, files in os.walk(folder_path):
        for file in files:
            ext = os.path.splitext(file)[1].lower()
            if ext in supported_formats:
                file_path = os.path.join(root, file)
                try:
                    # 获取文件元数据
                    audio = MutagenFile(file_path)
                    if audio:
                        title = audio.get('title', [os.path.splitext(file)[0]])[0] if hasattr(audio, 'get') else os.path.splitext(file)[0]
                        artist = audio.get('artist', ['未知歌手'])[0] if hasattr(audio, 'get') else '未知歌手'
                        album = audio.get('album', ['未知专辑'])[0] if hasattr(audio, 'get') else '未知专辑'
                        genre = audio.get('genre', ['未知曲风'])[0] if hasattr(audio, 'get') else '未知曲风'
                        duration = int(audio.info.length) if hasattr(audio, 'info') and hasattr(audio.info, 'length') else 0
                        
                        # 特殊处理不同格式
                        if isinstance(audio, mutagen.id3.ID3):
                            title = audio.get('TIT2', mutagen.id3.TIT2(encoding=3, text=os.path.splitext(file)[0])).text[0]
                            artist = audio.get('TPE1', mutagen.id3.TPE1(encoding=3, text=['未知歌手'])).text[0]
                            album = audio.get('TALB', mutagen.id3.TALB(encoding=3, text=['未知专辑'])).text[0]
                            genre = audio.get('TCON', mutagen.id3.TCON(encoding=3, text=['未知曲风'])).text[0]
                        elif isinstance(audio, mutagen.mp4.MP4):
                            title = audio.get('\xa9nam', [os.path.splitext(file)[0]])[0]
                            artist = audio.get('\xa9ART', ['未知歌手'])[0]
                            album = audio.get('\xa9alb', ['未知专辑'])[0]
                            genre = audio.get('\xa9gen', ['未知曲风'])[0]
                        elif isinstance(audio, mutagen.flac.FLAC):
                            title = audio.get('title', [os.path.splitext(file)[0]])[0]
                            artist = audio.get('artist', ['未知歌手'])[0]
                            album = audio.get('album', ['未知专辑'])[0]
                            genre = audio.get('genre', ['未知曲风'])[0]
                        elif isinstance(audio, mutagen.oggvorbis.OggVorbis):
                            title = audio.get('title', [os.path.splitext(file)[0]])[0]
                            artist = audio.get('artist', ['未知歌手'])[0]
                            album = audio.get('album', ['未知专辑'])[0]
                            genre = audio.get('genre', ['未知曲风'])[0]
                        
                        music_files.append({
                            'id': len(music_files) + 1,
                            'title': title,
                            'artist': artist,
                            'album': album,
                            'genre': genre,
                            'path': file_path,
                            'duration': duration,
                            'file_name': file,
                            'folder': root
                        })
                except Exception as e:
                    print(f"Error processing file {file_path}: {e}")
    return music_files

# API端点

@app.get("/api/config")
async def get_config():
    return config

@app.post("/api/config")
async def update_config(new_config: Dict[str, Any]):
    global config
    config.update(new_config)
    save_config(config)
    return {"status": "success"}

@app.post("/api/scan")
async def scan_folder(folder_path: str = Form(...)):
    if not os.path.exists(folder_path):
        raise HTTPException(status_code=404, detail="Folder not found")
    music_files = scan_music_files(folder_path)
    return {"status": "success", "files": music_files, "count": len(music_files)}

@app.post("/api/add-folder")
async def add_folder(folder_path: str = Form(...)):
    if not os.path.exists(folder_path):
        raise HTTPException(status_code=404, detail="Folder not found")
    if folder_path not in config["music_folders"]:
        config["music_folders"].append(folder_path)
        save_config(config)
    return {"status": "success", "folders": config["music_folders"]}

@app.post("/api/remove-folder")
async def remove_folder(folder_path: str = Form(...)):
    if folder_path in config["music_folders"]:
        config["music_folders"].remove(folder_path)
        save_config(config)
    return {"status": "success", "folders": config["music_folders"]}

@app.get("/api/music-files")
async def get_music_files():
    all_files = []
    for folder in config["music_folders"]:
        all_files.extend(scan_music_files(folder))
    return {"status": "success", "files": all_files, "count": len(all_files)}

@app.post("/api/playlists/create")
async def create_playlist(name: str = Form(...)):
    if name in config["playlists"]:
        raise HTTPException(status_code=400, detail="Playlist already exists")
    config["playlists"][name] = []
    save_config(config)
    return {"status": "success", "playlists": list(config["playlists"].keys())}

@app.post("/api/playlists/delete")
async def delete_playlist(name: str = Form(...)):
    if name in config["playlists"]:
        del config["playlists"][name]
        save_config(config)
    return {"status": "success", "playlists": list(config["playlists"].keys())}

@app.post("/api/playlists/rename")
async def rename_playlist(old_name: str = Form(...), new_name: str = Form(...)):
    if old_name in config["playlists"] and new_name not in config["playlists"]:
        config["playlists"][new_name] = config["playlists"].pop(old_name)
        save_config(config)
    return {"status": "success", "playlists": list(config["playlists"].keys())}

@app.post("/api/playlists/add-song")
async def add_song_to_playlist(playlist_name: str = Form(...), song_path: str = Form(...)):
    if playlist_name not in config["playlists"]:
        raise HTTPException(status_code=404, detail="Playlist not found")
    if song_path not in config["playlists"][playlist_name]:
        config["playlists"][playlist_name].append(song_path)
        save_config(config)
    return {"status": "success", "playlist": config["playlists"][playlist_name]}

@app.post("/api/playlists/remove-song")
async def remove_song_from_playlist(playlist_name: str = Form(...), song_path: str = Form(...)):
    if playlist_name not in config["playlists"]:
        raise HTTPException(status_code=404, detail="Playlist not found")
    if song_path in config["playlists"][playlist_name]:
        config["playlists"][playlist_name].remove(song_path)
        save_config(config)
    return {"status": "success", "playlist": config["playlists"][playlist_name]}

@app.get("/api/playlists")
async def get_playlists():
    return {"status": "success", "playlists": config["playlists"]}

@app.post("/api/search")
async def search_songs(query: str = Form(...)):
    all_files = []
    for folder in config["music_folders"]:
        all_files.extend(scan_music_files(folder))
    results = [f for f in all_files if query.lower() in f["title"].lower() or query.lower() in f["artist"].lower() or query.lower() in f["album"].lower()]
    return {"status": "success", "results": results, "count": len(results)}

@app.post("/api/play-mode")
async def set_play_mode(mode: str = Form(...)):
    if mode in ["order", "repeat", "shuffle"]:
        config["play_mode"] = mode
        save_config(config)
    return {"status": "success", "play_mode": config["play_mode"]}

@app.post("/api/volume")
async def set_volume(volume: str = Form(...)):
    try:
        volume_float = float(volume)
        config["volume"] = max(0.0, min(1.0, volume_float))
        save_config(config)
        return {"status": "success", "volume": config["volume"]}
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid volume value")

@app.post("/api/equalizer")
async def set_equalizer(preset: str = Form(...)):
    config["equalizer"] = preset
    save_config(config)
    return {"status": "success", "equalizer": config["equalizer"]}

@app.post("/api/update-metadata")
async def update_metadata(file_path: str = Form(...), title: str = Form(...), artist: str = Form(...), album: str = Form(...), genre: str = Form(...)):
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="File not found")
    
    audio = MutagenFile(file_path)
    if not audio:
        raise HTTPException(status_code=400, detail="Invalid audio file")
    
    try:
        if isinstance(audio, mutagen.id3.ID3):
            audio['TIT2'] = mutagen.id3.TIT2(encoding=3, text=title)
            audio['TPE1'] = mutagen.id3.TPE1(encoding=3, text=artist)
            audio['TALB'] = mutagen.id3.TALB(encoding=3, text=album)
            audio['TCON'] = mutagen.id3.TCON(encoding=3, text=genre)
        elif isinstance(audio, mutagen.mp4.MP4):
            audio['\xa9nam'] = title
            audio['\xa9ART'] = artist
            audio['\xa9alb'] = album
            audio['\xa9gen'] = genre
        elif isinstance(audio, mutagen.flac.FLAC):
            audio['title'] = title
            audio['artist'] = artist
            audio['album'] = album
            audio['genre'] = genre
        elif isinstance(audio, mutagen.oggvorbis.OggVorbis):
            audio['title'] = title
            audio['artist'] = artist
            audio['album'] = album
            audio['genre'] = genre
        
        audio.save()
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update metadata: {str(e)}")

@app.post("/api/clean-cache")
async def clean_cache():
    # 清理缓存逻辑
    cache_folder = Path('cache')
    if cache_folder.exists():
        shutil.rmtree(cache_folder)
        cache_folder.mkdir(exist_ok=True)
    return {"status": "success"}

if __name__ == "__main__":
    import uvicorn
    # 创建cache文件夹
    Path('cache').mkdir(exist_ok=True)
    uvicorn.run(app, host="0.0.0.0", port=8000)
