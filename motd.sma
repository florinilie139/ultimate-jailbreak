#include <amxmodx>
#include <amxmisc>

#define PLUG_NAME         "MOTD"
#define PLUG_AUTH         "(|EcLiPsE|)"
#define PLUG_VERS         "1.0"

#define MAXCMDL 30

new Commands[10][MAXCMDL]
new maxcmd = 0

public plugin_init() 
{
    register_plugin(PLUG_NAME, PLUG_VERS, PLUG_AUTH)
    load_file()
}

public load_file ()
{
    new file[250]
    new data[250], len, line = 0
    
    get_configsdir(file, 249)
    format(file, 249, "%s/motd.ini", file)
    log_amx("INI -> %s", file)
    
    if (!file_exists(file))
    {
        log_amx("no INI found")
        return
    }
    
    maxcmd = 0
    
    // INI zerlegen
    while((line = read_file(file , line , data , 249 , len) ) != 0 )
    {
        new cmd[MAXCMDL]    // Befehl    
        
        if ((data[0] == ';') || equal(data, "")) continue
        
        // zerlegen
        parse(data, cmd, MAXCMDL)
        
        format(Commands[maxcmd], 49, "%s", cmd)
        
        maxcmd++
    }
    log_amx("%i comenzi gasite", maxcmd)
}

public client_command(player) {
    
    // "Befehl" holen
    new cmd[50]
    read_argv(1, cmd, 49)

    // alles weiter reichen
    if (cmd[0] != '/') return PLUGIN_CONTINUE

    for(new i = 0; i < maxcmd; i++) 
        if (equali(cmd[1], Commands[i]))
        {
            format(cmd,50,"%s.html",Commands[i])
            if (!file_exists(cmd))
            {
                format(cmd,50,"%s.htm",Commands[i])
                if (!file_exists(cmd))
                {
                    format(cmd,50,"%s.txt",Commands[i])
                    if (!file_exists(cmd))
                    {
                        return PLUGIN_CONTINUE
                    }
                }
            }
            show_motd(player,cmd,Commands[i]);
            return PLUGIN_HANDLED
        }
    
    return PLUGIN_CONTINUE
}