import os
from argparse import ArgumentParser
from pathlib import Path
import re

HERE = Path(__file__).parent.absolute()

START_SCRIPTPACKAGE = re.compile(r"<ScriptPackage>")
END_SCRIPTPACKAGE = re.compile(r"</ScriptPackage>")
NO_SCRIPTPACKAGE = re.compile(r"<ScriptPackage />")
START_SCRIPT = re.compile(r"<script>")
END_SCRIPT = re.compile(r"</script>")


def extract(path=HERE):
    for obj in path.glob("*"):
        if obj.is_dir():
            extract(obj)
            continue
        if not obj.name.endswith(".xml"):
            continue
        lua_fn = str(obj).replace(".xml", ".lua")
        print("=" * 50)
        print(f"Extract Lua script from\n{obj}\ninto file\n{lua_fn}")
        extract_file(obj, lua_fn)


def extract_file(from_file, to_file):
    no_script = False
    with open(from_file, "r", encoding="utf-8") as ff, open(
        to_file, "w", encoding="utf-8"
    ) as tf:
        status = 0
        for line in ff:
            if re.search(NO_SCRIPTPACKAGE, line):
                no_script = True
                break
            if status == 0 and re.search(START_SCRIPTPACKAGE, line):
                status = extract_pre_package(line)
            elif status == 1:
                status = extract_comment(line, tf)
            elif status == 2:
                status = extract_script(line, tf)
            elif status == 3:
                break
    if no_script:
        os.remove(to_file)
        print(f"Remove file {to_file} because there is no script in it")


def extract_pre_package(line):
    if re.search(START_SCRIPTPACKAGE, line):
        return 1
    return 0


def extract_comment(line, tf):
    if re.search(END_SCRIPTPACKAGE, line):
        return 3
    tf.write(f"--##{line}")
    if re.search(START_SCRIPT, line) and not re.search(END_SCRIPT, line):
        tf.write(line.lstrip().replace("<script>", ""))
        return 2
    return 1


def extract_script(line, tf):
    if re.search(END_SCRIPT, line):
        tf.write(line.replace("</script>", ""))
        tf.write(f"--##{line}")
        return 1
    tf.write(line)
    return 2


def include():
    for lua_fn in HERE.glob("*.lua"):
        obj = str(lua_fn).replace(".lua", ".xml")
        print("=" * 50)
        print(f"Include Lua script from\n{lua_fn}\nback into file\n{obj}")
        include_file(lua_fn, obj)


def include_file(from_file, to_file):
    with open(from_file, "r", encoding="utf-8") as ff:
        lines = list(ff)

    script = []
    i = 0
    for _ in range(len(lines)):
        if i == len(lines):
            break
        if re.search(START_SCRIPT, lines[i]):
            if not re.search(END_SCRIPT, lines[i]):
                script.append(lines[i].replace("--##", ""))
                i += 2
                continue
        elif re.search(END_SCRIPT, lines[i]):
            script[-1] = lines[i].replace("--##", "")
            i += 1
            continue
        script.append(lines[i].replace("--##", ""))
        i += 1

    status = 0
    pre_script, post_script = [], []
    with open(to_file, "r", encoding="utf-8") as tf:
        for line in tf:
            if status == 0:
                pre_script.append(line)
                if re.search(START_SCRIPTPACKAGE, line):
                    status = 1
            elif status == 1:
                if re.search(END_SCRIPTPACKAGE, line):
                    post_script.append(line)
                    status = 2
            else:
                post_script.append(line)

    with open(to_file, "w", encoding="utf-8") as tf:
        for line in pre_script + script + post_script:
            tf.write(line)


def main():
    parser = ArgumentParser()

    parser.add_argument(
        "-e",
        "--extract",
        help="Extract lua scripts from files.",
        action="store_true",
    )
    parser.add_argument(
        "-i",
        "--include",
        help="Include lua scripts into files.",
        action="store_true",
    )

    args = parser.parse_args()

    if args.extract:
        extract()

    if args.include:
        include()


if __name__ == "__main__":
    main()
