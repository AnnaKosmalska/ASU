#!/usr/bin/perl
use strict;
use Getopt::Long;
use feature 'say';
use String::MkPasswd qw(mkpasswd);
use Tk;
use File::Copy;

# setup my defaults
my $user = '';
my $create = '';
my $passwd = '';
my $help = '';
my $uid = '';
my $randpasswd = '';
my $copydir = '';
my $save = '';
my $groupadd = '';
my $groupdel = '';
my $delete = '';
my $interactive = '';
my $shell = '';


GetOptions(
    'user=s'          => \$user,
    'create=s'      => \$create,
    'passwd=s'      => \$passwd,
    'uid=s'         => \$uid,
    'help!'         => \$help,
    'randpasswd'    => \$randpasswd,
    'copydir=s'     => \$copydir,
    'save=s'        => \$save,
    'groupadd=s'    => \$groupadd,
    'groupdel=s'    => \$groupdel,
    'delete=s'      => \$delete,
    'interactive'   => \$interactive,
    'shell=s'         => \$shell,
    
) or die "Incorrect usage!\n";

#jezeli tworzymy nowego uzytkownika
if ($create ne '') {
    my $command = '-d /home/' . $create . ' -m ' . $create;
    my $ret;
    
    #dajemy mu UID
    if($uid ne '') {
        my $ok = uid_free($uid);
        if ($ok == 1) {
            $command = '-u ' . $uid . ' ' . $command; 
        }
        else {
            my $newuid = getUID();  
            say 'Brak takiego UID! Twoje UID to ' . $newuid;      
            $command = '-u ' . $newuid . ' ' . $command;
        }
    }
    else {
        my $newuid = getUID();
        
        $command = '-u ' . $newuid . ' ' . $command; 
    }    
    
    #dajemy mu haslo
    if($passwd ne '') {
        my $pass = `openssl passwd -crypt $passwd`;
        chomp($pass);
        $command = '-p ' . $pass . ' ' . $command;
    }
    elsif ($randpasswd) {
        my $pass = mkpasswd();
        $pass = `openssl passwd -crypt $pass`;
        chomp($pass);
        say 'Twoje haslo to ' . $pass;
        $command = '-p ' . $pass . ' ' . $command;
    }
    
    $ret = `useradd $command`;
    say $ret;
    #say 'useradd ' . $command;
        
}

#modyfikacja uzytkownika
elsif($user ne '') {

    #dodajemy do grupy
    if($groupadd ne '') {
        my $ret; 
        $ret = `gpasswd -a $user $groupadd`;
        say $ret;
        #say "gpasswd -a " . $user . " " . $groupadd;
    }
    
    #usuwamy z grupy
    if($groupdel ne '') {
        my $ret; 
        $ret = `gpasswd -d $user $groupdel`;
        say $ret;
        #say "gpasswd -d " . $user . " " . $groupdel;
    }
    
    #zmiana shella
    if($shell ne '') {
        my $ret;
        $ret = `chsh -s $shell $user`;
        say $ret;
        #say 'chsh -s ' . $shell . ' ' .$user;
    }
    
    #kopiowanie plikow kropkowych
    if($copydir ne '') {
        my $source = $copydir;
        my $dest = '/home/' . $user;
        opendir(my $DIR, $source) || die 'nieprawidlowy katalog ' . $source . '!';
        my @files = readdir($DIR);
        foreach my $file (@files) {
            if (-f '$source/$file') {
                copy('$source/$file', '$dest/' . '.' . '$file') or die 'Kopiowanie nie udalo sie!';
                say 'copy ' . '$source/$file'.','. '$dest/' . '.' . '$file';
            }
        }
        closedir($DIR);
    }
    
    #zapisanie danych
    if($save ne '') {
        my $fileDesc;
        my $file = $save;
        open($fileDesc, ">", $file) or die 'Nie udalo sie otworzyc pliku do zapisu';
        my ($name, $pass, $uid, $gid, $quota, $comment, $gcos, $dir, $shell, $expire) = getpwnam($user);
        my $toprint = 'login: ' . $user . ' uid: ' . $uid . ' haslo: ' . $pass;
        printf($fileDesc $toprint);
        close($fileDesc);
    }
    

}

#usuwamy uzytkownika
elsif($delete) {
    my $ret;    
    $ret = `userdel -r $delete`;
    say $ret;
    #say "userdel -r " . $delete;
}

elsif($help) {
    my $help = '
    perl users.pl [opcje]
    -user login [-groupadd group] [-groupdel group]
        [-shell shell] [-copydir dir] [-save file]
    -create login [-uid uid] [-passwd password] | [-randpasswd]
    -help
    -delete login';
    say $help;
}

#czy uid jest wolny
sub uid_free {
    my $newuid = @_[0];
    while (my ($name, $pass, $uid, $gid, $quota, $comment, $gcos, $dir, $shell, $expire) = getpwent()) {
        if ($uid == $newuid) {
            return 0;
        }
    }
    return 1;
}

#znajdujemy wolny UID
sub getUID {
    my $newuid = 100;
    while(uid_free($newuid) == 0) {
        $newuid = $newuid+1;
    }
    return $newuid;
}




























