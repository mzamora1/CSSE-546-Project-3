There are 2 ways to run this project, either Pre-build VM or build VM from
scratch

Pre-built VM:

1. Download prebuild VM from here
2. Under VM settings > Options > Shared Folders, make sure an enabled shared
   folder called 'Project 3' points to your local git repo
3. Launch the VM
4. Run output bucket printer server

```bash
python3 '/mnt/hgfs/Project 3/printer/app.py'
```

5. In a new terminal, run workload generator

```bash
cd '/mnt/hgfs/Project 3/test' && python3 workload.py
```

6. Check output in /tmp/csv, printer logs, and output bucket

Build VM:

1. Download Ubuntu ISO from LinuxVMImages
2. Set RAM to at least 8192 (8 GB), optionally 4 cores
3. Add 3 Hard Drives. At least 20 GB each, single file, optionally named OSD-0,
   OSD-1, OSD-2
4. Under Options, Add a readonly shared folder to local git repo named 'Project
   3'
5. Start VM, login with Password = ubuntu
6. Add Copy/Paste, Shared Folders using pre_setup.sh (follow instructions inside
   file)

7. Bootstrap Openfaas

If this command Could not get lock, restart VM and wait for updates to complete.
Updates could take a while (5 - 10 mins)

```bash
cd '/mnt/hgfs/Project 3' && source setup_openfaas.sh
```

8. Bootstrap Ceph

```bash
cd '/mnt/hgfs/Project 3' && source setup_ceph.sh
```

9. Go to test folder

```bash
cd '/mnt/hgfs/Project 3/test'
```

10. Make sure your enviornment have these variables with corresponding values
    stored.<br /> AWS_ACCESS_KEY_ID_S3="RGW Access Key"<br />
    AWS_SECRET_ACCESS_KEY_S3="RGW Secret Key"<br /> RGW_URL="RGW Endpoint (Mon
    IP)<br/> Restart VM, or use the same terminal from setup_ceph if not
    found<br/>

11. Run workload generator

```bash
python3 workload.py
```

12. After some time, output bucket should have 100 object, check this and then
    run "checkMapping.py" to validate the outputs.

<br>
This took about 7:15 mins with 2 core 8 GB ram
<br>
Or about 6:10 mins with 4 core 8 GB ram
