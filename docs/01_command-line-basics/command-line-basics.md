# Command Line Basics

If you have never used a command line before, don't worry — this section covers everything you need to know to get started. The command line is simply a text-based way of interacting with a computer. Instead of clicking on icons, you type commands. It may feel unfamiliar at first, but you will quickly find that it is a powerful and efficient way to work.

If you want to go deeper after this workshop, UF Research Computing has a more comprehensive Linux tutorial at [https://github.com/UFResearchComputing/Linux_training](https://github.com/UFResearchComputing/Linux_training).

## Opening a Terminal

**Mac:** Open the Terminal app by going to Applications → Utilities → Terminal, or search for "Terminal" in Spotlight (`Cmd+Space`).

**Windows:** We recommend installing [Git Bash](https://gitforwindows.org/) or [MobaXTerm](https://mobaxterm.mobatek.net/download.html) which gives you a Linux-style terminal on Windows. Once installed, open it from the Start menu. Alternatively, Windows 10 and 11 have a built-in Linux terminal called WSL (Windows Subsystem for Linux) which you can enable through the Microsoft Store.

Once your terminal is open, you will see a command prompt that looks something like this:

```
username@computer:~$
```

This tells you your username, the name of the computer you are on, and your current directory (`~` is shorthand for your home directory). You type commands after the `$` and press `Enter` to run them.

## Navigating the Filesystem

First, make sure you are in your home directory. Everyone's will look different, but `~` is a universal shorthand that always means "your home directory" no matter what system you are on:

```bash
cd ~
pwd
```

> Your output will look something like `/home/username` on Linux, `/Users/username` on Mac, or something similar on Windows. That's expected — everyone's will be different.

<span class="command-title">ls — list files</span>

`ls` lists the files and directories in your current directory. Your home directory may have some files already — that's fine:

```bash
ls
```

The `-l` flag gives you a long format with permissions, size, and date. Adding `h` makes file sizes human-readable (KB, MB, GB). Adding `a` includes hidden files that start with a dot:

```bash
ls -l
```

```bash
ls -lh
```

```bash
ls -la
```

<span class="command-title">cd — change directory</span>

`cd` moves you into a different directory. `cd ..` goes up one level, `cd ~` always takes you back to your home directory, and `cd -` takes you back to wherever you just were:

```bash
cd ..
```

```bash
cd ~
```

```bash
cd -
```

## Setting Up a Practice Directory

Before we go further, let's create a dedicated space to practice in so we don't clutter your home directory.

<span class="command-title">mkdir — make directory</span>

```bash
cd ~
mkdir command_line_practice
cd command_line_practice
pwd
```

> Your path will look different, but you should see `command_line_practice` at the end.

Now let's create some subdirectories. The `-p` flag lets you create nested directories all at once:

```bash
mkdir notes
mkdir -p data/raw
ls
```

> `data  notes`

## Creating Files

<span class="command-title">cat with redirection — quick file creation</span>

The quickest way to create a small file is to use a heredoc — the `<< 'EOF'` syntax tells the shell to treat everything that follows as file content until it sees `EOF` on a line by itself, making it safe to copy and paste:

```bash
cat > notes/hello.txt << 'EOF'
Hello world, this is my first file.
I am learning the command line.
This is line three.
EOF
```

Let's create a second file:

```bash
cat > notes/genes.txt  << 'EOF'
TP53 is a tumor suppressor gene.
BRCA1 is associated with breast cancer risk.
EGFR is a common target in lung cancer therapy.
TP53 mutations are found in many cancer types.
EOF
```

See the files you created:

```bash
ls notes
```

<span class="command-title">nano — interactive text editor</span>

`nano` is a simple text editor that runs in the terminal and is better for longer files. To open or create a file:

```bash
nano notes/myfile.txt
```

Type whatever you like, then use these commands to save and exit:

| **Action** | **Keys** |
|---|---|
| Exit and Save | `Ctrl+X`  then `Y`|
| Cut a line | `Ctrl+K` |
| Paste | `Ctrl+U` |
| Search | `Ctrl+W` |

The bottom of the nano screen always shows available commands, so you don't need to memorize them.

## Viewing File Contents

<span class="command-title">cat — print entire file</span>

```bash
cat notes/hello.txt
```

> Hello world, this is my first file.  
> I am learning the command line.  
> This is line three.

<span class="command-title">head and tail — print the beginning or end of a file</span>

`head` prints the first 10 lines of a file by default, and `tail` prints the last 10. The `-n` flag lets you specify how many lines you want. `head` is particularly useful for quickly checking the format of large files without printing the whole thing:

```bash
head notes/genes.txt
```

```bash
head -n 2 notes/genes.txt
```

```bash
tail -n 2 notes/genes.txt
```

## Managing Files and Directories

<span class="command-title">cp — copy</span>

To copy a file, give `cp` the source and the destination. The `-r` flag copies a whole directory and everything inside it:

```bash
cp notes/hello.txt notes/hello_backup.txt
ls notes/
```

> `genes.txt  hello.txt  hello_backup.txt  myfile.txt`

```bash
cp -r notes data/
ls data/
```

> `notes  raw`

<span class="command-title">mv — move or rename</span>

`mv` works for both moving a file to a new location and renaming it — it's the same operation:

```bash
mv notes/hello_backup.txt data/
mv notes/myfile.txt notes/myfile_renamed.txt
ls notes/
```

> `genes.txt  hello.txt  myfile_renamed.txt`

<span class="command-title">rm — remove</span>

```bash
rm notes/myfile_renamed.txt
ls notes/
```

> `genes.txt  hello.txt`

!!! warning "There is no trash bin on the command line"
    Deleted files are gone permanently. Always double-check before using `rm -r`.

## Input/Output Redirection

By default, commands print their output to the screen. The `>` operator redirects that output into a file instead, creating it if it doesn't exist and overwriting it if it does. The `>>` operator appends to a file rather than overwriting it:

```bash
ls -lh notes/ > data/file_list.txt
```

```bash
ls -lh data/ >> data/file_list.txt
```

Let's check what ended up in the file:

```bash
cat data/file_list.txt
```

> `-rw-r--r-- 1 username group 142 Apr  8 10:00 genes.txt`  
> `-rw-r--r-- 1 username group  73 Apr  8 10:00 hello.txt`  
> ...

Saving output to a file is useful for keeping records of what a command produced, or for checking the output of long-running jobs later.

## Pipes

Pipes (`|`) let you chain commands together, sending the output of one command as the input to the next:

```bash
cat notes/genes.txt | head -2
```

> TP53 is a tumor suppressor gene.  
> BRCA1 is associated with breast cancer risk.

```bash
ls -lh notes/ | grep "genes"
```

> `-rw-r--r-- 1 username group 142 Apr  8 10:00 genes.txt`

## Searching with grep

<span class="command-title">grep — search for a pattern</span>

`grep` searches for a pattern in a file and prints every line that matches. The `-i` flag makes the search case-insensitive, and `-c` counts the number of matching lines instead of printing them:

```bash
grep "TP53" notes/genes.txt
```

> TP53 is a tumor suppressor gene.  
> TP53 mutations are found in many cancer types.

```bash
grep -i "brca" notes/genes.txt
```

```bash
grep -c "TP53" notes/genes.txt
```

> `2`

Combined with pipes, `grep` is very powerful for filtering output:

```bash
cat notes/genes.txt | grep "cancer"
```

> BRCA1 is associated with breast cancer risk.  
> EGFR is a common target in lung cancer therapy.  
> TP53 mutations are found in many cancer types.

## Getting Help

Almost every command has a manual page you can access with `man`, and most also accept `--help` for a quick summary of options. When in doubt, these are your first resources before searching online:

```bash
man ls
```

type `q` to get out of the manual


## Cleaning Up

Once you're done practicing, you can remove the whole practice directory.

!!! warning "Reminder"
    `rm -r` permanently deletes everything inside. Make sure you are in your home directory (`cd ~`) and are removing the right directory before running this.

```bash
cd ~
rm -r command_line_practice
```

