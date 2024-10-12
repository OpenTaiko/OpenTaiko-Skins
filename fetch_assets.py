import os
import json

# Function to find all files within a folder while ignoring "Replay" folders
def find_files(folder):
    file_paths = []
    for root, _, files in os.walk(folder):
        for file in files:
            file_paths.append(os.path.join(root, file))
    return file_paths

# Function to calculate the total size of files in bytes
def calculate_total_size(file_paths):
    total_size = 0
    for file_path in file_paths:
        total_size += os.path.getsize(file_path)
    return total_size / (1024 * 1024)  # Convert bytes to megabytes

# Function to parse skin config files and extract the necessary metadata
def parse_skin_config(config_file_path, base_path):
    skin_name = "Unknown"
    skin_version = "Unknown"
    skin_creator = "Unknown"
    skin_resolution = "1280,720"
    
    try:
        with open(config_file_path, "r", encoding="utf-8-sig", errors="ignore") as skin_config:
            for line in skin_config:
                line = line.strip()
                
                if line.startswith("Name="):
                    skin_name = line.split("Name=", 1)[1].strip()
                elif line.startswith("Version="):
                    skin_version = line.split("Version=", 1)[1].strip()
                elif line.startswith("Creator="):
                    skin_creator = line.split("Creator=", 1)[1].strip()
                elif line.startswith("Resolution="):
                    skin_resolution = line.split("Resolution=", 1)[1].strip()
    except Exception as e:
        print(f"Error parsing {config_file_path}: {e}")

    return {
        "skinName": skin_name,
        "skinVersion": skin_version,
        "skinCreator": skin_creator,
        "skinResolution": skin_resolution
    }


def process_skins(system_path):
    data = []

    for root, _, files in os.walk(system_path):
        for file in files:
            if file == ("SkinConfig.ini"):
                skin_config_path = os.path.join(root, file)
                skin_folder = os.path.basename(root)
                
                # Find all files within the skin folder
                skin_folder_files = find_files(root)
                skin_files_paths = [os.path.relpath(file, system_path) for file in skin_folder_files]
                
                # Calculate total size of all files in the skin folder
                total_size_mb = calculate_total_size(skin_folder_files)
                
                # Parse .tja file for metadata
                skin_metadata = parse_skin_config(skin_config_path, system_path)

                # Add the tja file data to the list
                data.append({
                    "skinFolder": skin_folder,
                    "skinFolderPath": os.path.relpath(root, system_path),
                    "skinPreviewImage": os.path.join(skin_folder, "Graphics\\1_Title\\Background.png"),
                    "skinName": skin_metadata.get("skinName"),
                    "skinVersion": skin_metadata.get("skinVersion"),
                    "skinCreator": skin_metadata.get("skinCreator"),
                    "skinResolution": skin_metadata.get("skinResolution"),
                    "skinSize": round(total_size_mb, 2),  # Size in MB, rounded to 2 decimal places
                    "skinFilesPath": skin_files_paths 
                })

    return data

# Main function to create the JSON output
def create_assets_json(base_path, output_file):
    data = {}
    data["Skins"] = process_skins(os.path.join(base_path, "System"))
    
    with open(output_file, "w", encoding="utf-8") as json_file:
        json.dump(data, json_file, indent=4)
        
if __name__ == "__main__":
    base_directory = os.getcwd()
    output_json_file = "assets_info.json"
    create_assets_json(base_directory, output_json_file)
    print(f"JSON file '{output_json_file}' created successfully.")
