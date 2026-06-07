import os

REPLACEMENTS = [
    ("Lab Tester", "Pathologist"),
    ("lab tester", "pathologist"),
    ("Lab_Tester", "Pathologist"),
    ("labTester", "pathologist"),
    ("lab_tester", "pathologist"),
    ("LabTester", "Pathologist"),
    ("LAB_TESTER", "PATHOLOGIST")
]

# We should process files in Backend and Frontend
target_dirs = ["Backend", "Frontend"]

for d in target_dirs:
    for root, dirs, files in os.walk(d):
        if "build" in root or ".pub-cache" in root or ".dart_tool" in root or "node_modules" in root or "public" in root:
            continue
        for file in files:
            # Only process certain extensions
            if file.endswith(".js") or file.endswith(".dart") or file.endswith(".md") or file.endswith(".yaml"):
                filepath = os.path.join(root, file)
                
                # First rename the content
                try:
                    with open(filepath, "r", encoding="utf-8") as f:
                        content = f.read()
                    
                    new_content = content
                    for old, new in REPLACEMENTS:
                        new_content = new_content.replace(old, new)
                        
                    if new_content != content:
                        with open(filepath, "w", encoding="utf-8") as f:
                            f.write(new_content)
                        print(f"Updated content in {filepath}")
                except Exception as e:
                    print(f"Error reading {filepath}: {e}")
                
                # Then rename the file if it contains 'labtester' or 'lab_tester'
                new_file = file
                for old, new in [("labTester", "pathologist"), ("lab_tester", "pathologist")]:
                    new_file = new_file.replace(old, new)
                
                if new_file != file:
                    new_filepath = os.path.join(root, new_file)
                    os.rename(filepath, new_filepath)
                    print(f"Renamed {filepath} to {new_filepath}")
