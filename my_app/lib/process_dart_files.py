import os

def find_dart_files(directory):
    """Находит все файлы с расширением .dart в указанной директории и её подкаталогах."""
    dart_files = []
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".dart"):
                dart_files.append(os.path.join(root, file))
    return dart_files

def write_to_project_txt(dart_files, output_file):
    """Записывает содержимое всех найденных .dart файлов в указанный файл project.txt."""
    with open(output_file, "w", encoding="utf-8") as project_file:
        for dart_file in dart_files:
            # Записываем полный путь к файлу
            project_file.write(f"File Path: {os.path.abspath(dart_file)}\n")
            project_file.write("Content:\n")
            # Читаем и записываем содержимое файла
            try:
                with open(dart_file, "r", encoding="utf-8") as current_file:
                    project_file.write(current_file.read())
            except Exception as e:
                project_file.write(f"Error reading file: {e}\n")
            # Разделитель между файлами
            project_file.write("\n" + "-" * 50 + "\n")

if __name__ == "__main__":
    # Определяем текущую директорию, где находится скрипт
    current_directory = os.path.dirname(os.path.abspath(__file__))
    
    # Находим все .dart файлы
    dart_files = find_dart_files(current_directory)
    
    # Создаём или перезаписываем файл project.txt
    output_file = os.path.join(current_directory, "project.txt")
    
    # Записываем информацию в project.txt
    write_to_project_txt(dart_files, output_file)
    
    print(f"Информация успешно записана в файл {output_file}")