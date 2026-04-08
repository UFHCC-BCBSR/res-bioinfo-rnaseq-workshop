# Command Line Basics

If you have never used a command line before, don't worry — this section covers everything you need to know to get started. The command line is simply a text-based way of interacting with a computer. Instead of clicking on icons, you type commands. It may feel unfamiliar at first, but you will quickly find that it is a powerful and efficient way to work.

If you want to go deeper after this workshop, UF Research Computing has a more comprehensive Linux tutorial at [https://github.com/UFResearchComputing/Linux_training](https://github.com/UFResearchComputing/Linux_training).

## The Command Prompt

### Opening a Terminal

**Mac:** Open the Terminal app by going to Applications → Utilities → Terminal, or search for "Terminal" in Spotlight (`Cmd+Space`).

**Windows:** We recommend installing [Git Bash](https://gitforwindows.org/) or [MobaXTerm](https://mobaxterm.mobatek.net/download.html) which gives you a Linux-style terminal on Windows. Once installed, open it from the Start menu. Alternatively, Windows 10 and 11 have a built-in Linux terminal called WSL (Windows Subsystem for Linux) which you can enable through the Microsoft Store.

Once your terminal is open, you will see a command prompt that looks something like this:

```
username@computer:~$
```

This tells you your username, the name of the computer you are on, and your current directory (`~` is shorthand for your home directory). You type commands after the `$` and press `Enter` to run them.

## Navigating the Filesystem

### `pwd` — print working directory

At any point you can find out exactly where you are in the filesystem with `pwd`:

```
$ pwd
/home/username
```

### `ls` — list files

`ls` lists the files and directories in your current directory:

```
$ ls
data  results  scripts
```

A few useful variations:

```
$ ls -l        # long format, shows permissions, size, and date
$ ls -lh       # same but with human-readable file sizes (KB, MB, GB)
$ ls -la       # includes hidden files (those starting with a dot)
```

### `cd` — change directory

`cd` moves you into a different directory:

```
$ cd scripts
$ pwd
/home/username/scripts
```

A few useful shortcuts:

```
$ cd ..        # go up one directory
$ cd ~         # go to your home directory
$ cd -         # go back to the previous directory
```

## Managing Files and Directories

### `mkdir` — make directory

```
$ mkdir results
$ mkdir -p results/counts/raw    # create nested directories all at once
```

### `cp` — copy

```
$ cp file1.txt file2.txt              # copy a file
$ cp -r dir1 dir2                     # copy a directory and all its contents
```

### `mv` — move or rename

```
$ mv file1.txt results/               # move a file into a directory
$ mv old_name.txt new_name.txt        # rename a file
```

### `rm` — remove

```
$ rm file1.txt                        # delete a file
$ rm -r results/                      # delete a directory and all its contents
```

> **Warning:** There is no trash bin on the command line. Deleted files are gone permanently. Be careful with `rm -r`.

## Viewing File Contents

### `cat` — print entire file

```
$ cat sample_sheet.csv
```

### `head` and `tail` — print the beginning or end of a file

```
$ head sample_sheet.csv          # first 10 lines
$ head -n 20 sample_sheet.csv   # first 20 lines
$ tail sample_sheet.csv          # last 10 lines
$ tail -n 20 sample_sheet.csv   # last 20 lines
```

`head` is particularly useful for quickly checking the format of large files without printing the whole thing.

## Editing Files with nano

`nano` is a simple text editor that runs in the terminal. To open or create a file:

```
$ nano myscript.sh
```

Key commands inside nano:

| **Action** | **Keys** |
|---|---|
| Save | `Ctrl+O`, then `Enter` |
| Exit | `Ctrl+X` |
| Cut a line | `Ctrl+K` |
| Paste | `Ctrl+U` |
| Search | `Ctrl+W` |

The bottom of the nano screen always shows available commands, so you don't need to memorize them.

## Input/Output Redirection

By default, commands print their output to the screen. You can redirect that output to a file instead:

```
$ ls -lh > file_list.txt          # write output to a file (overwrites if it exists)
$ ls -lh >> file_list.txt         # append output to a file
$ my_command &> output.log        # redirect both output and errors to a file
```

Saving output to a file is useful for keeping records of what a command produced, or for checking the output of long-running jobs later.

## Pipes

Pipes (`|`) let you chain commands together, sending the output of one command as the input to the next:

```
$ cat sample_sheet.csv | head -5       # print just the first 5 lines of a file
$ ls -lh | grep ".fastq"               # list only files with .fastq in the name
```

## Searching with grep

`grep` searches for a pattern in a file or input:

```
$ grep "panama" sample_sheet.csv              # find all lines containing "panama"
$ grep -i "panama" sample_sheet.csv           # case-insensitive search
$ grep -c "panama" sample_sheet.csv           # count matching lines
```

Combined with pipes, `grep` is very powerful:

```
$ cat sample_sheet.csv | grep "high"          # filter lines containing "high"
```

## Getting Help

Almost every command has a manual page you can access with `man`:

```
$ man ls
$ man grep
```

You can also usually get a quick summary of options with `--help`:

```
$ ls --help
$ grep --help
```

When in doubt, these are your first resources before searching online.
