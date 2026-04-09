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

A few useful variations:

```bash
ls -l        # long format, shows permissions, size, and date
ls -lh       # same but with human-readable file sizes (KB, MB, GB)
ls -la       # includes hidden files (those starting with a dot)
```

<span class="command-title">cd — change directory</span>

`cd` moves you into a different directory. A few useful shortcuts:

```bash
cd ..        # go up one directory
cd ~         # go to your home directory
cd -         # go back to the previous directory
```

## Setting Up a Practice Directory

Before we go further, let's create a dedicated space to practice in so we don't clutter your home directory.

<span class="command-title">mkdir — make directory</span>

```bash
mkdir command_line_practice
cd command_line_practice
pwd
```

> Your path will look different, but you should see `command_line_practice` at the end.

Now let's create some subdirectories:

```bash
mkdir notes
mkdir -p data/raw    # create nested directories all at once
ls
```

> `data  notes`

## Creating Files

<span class="command-title">cat with redirection — quick file creation</span>

The quickest way to create a small file is to use `cat` with the `>` redirect operator. Type the command, press `Enter`, type your content, then press `Ctrl+D` to save:

```bash
cat > notes/hello.txt
Hello world, this is my first file.
I am learning the command line.
This is line three.
```

*(press `Ctrl+D` to save)*

Let's create a second file:

```bash
cat > notes/genes.txt
TP53 is a tumor suppressor gene.
BRCA1 is associated with breast cancer risk.
EGFR is a common target in lung cancer therapy.
TP53 mutations are found in many cancer types.
```

*(press `Ctrl+D` to save)*

<span class="command-title">nano — interactive text editor</span>

`nano` is a simple text editor that runs in the terminal and is better for longer files. To open or create a file:

```bash
nano notes/myfile.txt
```

Type whatever you like, then use these commands to save and exit:

| **Action** | **Keys** |
|---|---|
| Save | `Ctrl+O`, then `Enter` |
| Exit | `Ctrl+X` |
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

```bash
head notes/genes.txt        # first 10 lines (shows all 4 in our case)
head -n 2 notes/genes.txt   # first 2 lines
tail -n 2 notes/genes.txt   # last 2 lines
```

`head` is particularly useful for quickly checking the format of large files without printing the whole thing.

## Managing Files and Directories

<span class="command-title">cp — copy</span>

```bash
cp notes/hello.txt notes/hello_backup.txt     # copy a file
ls notes/
```

> `genes.txt  hello.txt  hello_backup.txt  myfile.txt`

```bash
cp -r notes data/                             # copy a directory and all its contents
ls data/
```

> `notes  raw`

<span class="command-title">mv — move or rename</span>

```bash
mv notes/hello_backup.txt data/               # move a file into a directory
mv notes/myfile.txt notes/myfile_renamed.txt  # rename a file
ls notes/
```

> `genes.txt  hello.txt  myfile_renamed.txt`

<span class="command-title">rm — remove</span>

```bash
rm notes/myfile_renamed.txt                   # delete a file
ls notes/
```

> `genes.txt  hello.txt`

!!! warning "There is no trash bin on the command line"
    Deleted files are gone permanently. Always double-check before using `rm -r`.

## Input/Output Redirection

By default, commands print their output to the screen. You can redirect that output to a file instead:

```bash
ls -lh notes/ > data/file_list.txt           # write output to a file (overwrites if it exists)
ls -lh data/ >> data/file_list.txt           # append output to a file
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
cat notes/genes.txt | head -2                # print just the first 2 lines
```

> TP53 is a tumor suppressor gene.  
> BRCA1 is associated with breast cancer risk.

```bash
ls -lh notes/ | grep "genes"                 # list only files with "genes" in the name
```

> `-rw-r--r-- 1 username group 142 Apr  8 10:00 genes.txt`

## Searching with grep

<span class="command-title">grep — search for a pattern</span>

`grep` searches for a pattern in a file or input:

```bash
grep "TP53" notes/genes.txt                  # find all lines containing "TP53"
```

> TP53 is a tumor suppressor gene.  
> TP53 mutations are found in many cancer types.

```bash
grep -i "brca" notes/genes.txt               # case-insensitive search
grep -c "TP53" notes/genes.txt               # count matching lines
```

> `2`

Combined with pipes, `grep` is very powerful:

```bash
cat notes/genes.txt | grep "cancer"
```

> BRCA1 is associated with breast cancer risk.  
> EGFR is a common target in lung cancer therapy.  
> TP53 mutations are found in many cancer types.

## Getting Help

Almost every command has a manual page you can access with `man`:

```bash
man ls
man grep
```

You can also usually get a quick summary of options with `--help`:

```bash
ls --help
grep --help
```

When in doubt, these are your first resources before searching online.

## Cleaning Up

Once you're done practicing, you can remove the whole practice directory:

```bash
cd ~
rm -r command_line_practice
```

!!! warning "Reminder"
    `rm -r` permanently deletes everything inside. Make sure you are in your home directory (`cd ~`) and are removing the right directory before running this.