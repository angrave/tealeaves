#!/usr/bin/env python3

import csv

from boxsdk import Client, OAuth2, BoxAPIException
from boxsdk.object.folder import Folder
from boxsdk.object.file import File
from boxsdk.object.collaboration import CollaborationRole

import click
# TODO folders can be created using create_subfolder (but used rclone) 
# https://github.com/box/box-python-sdk/blob/master/docs/usage/folders.md#get-information-about-a-folder

def main():
    auth = OAuth2(
            client_id='',
            client_secret='',
            access_token=''# Box 1 hour developer token here
        )
    client = Client(auth)

    # Read in list of users
    with open("roster.txt", "r") as fd:
        netids = fd.read().splitlines()

    # Assumes you already made a folder for every netid and put the whole structure in box e.g. with rclone
    # for i in `cat roster.txt` ; do mkdir somewhere/$i-cs241-fa202; done
    student_email_map = { f"{netid}-cs241-fa2020":f"{netid}@illinois.edu"  for netid in netids}
    
    # Get the folderid to the base folder directly from Web interface
    base_folder_id = '128048149082'
    base_folder_expected_name = 'cs241-fa2020-final'
    # This is safer than search()
    
    base_folder = client.folder(folder_id=base_folder_id).get()
    assert base_folder.name == base_folder_expected_name
      
    # I cannot force get_items to return the folder name here, and pulling the folder object is sooo slow
    existing_items = base_folder.get_items(fields='id,type',limit=9999); 
    
    # I prefer this approach of returning all subfolders to using search() because it avoids potential partial matches being returned first by Box
    
    # Sanity check that the number of folders is the same as the number of students
    existing_items_ids =[i.id for i in existing_items if i.type=='folder']
    assert len(existing_items_ids) == len(netids)
    
    #If true adds students as collaborator to their own folder. If false, removes them
    enable_students = True
    
    for i in existing_items_ids:
        folder= client.folder(i).get()
        email = student_email_map[folder.name]
        if enable_students:
            print(f"{folder.name}->{email}")
            try:
                collaboration = folder.collaborate_with_login(email, CollaborationRole.EDITOR)
            except BoxAPIException as e:
                print(e)
        else:
            # Remove student collaborator
            collaborations = folder.get_collaborations()
            for collab in collaborations:
                target = collab.accessible_by
                # Runtime error: target can be 'None'
                if target:
                    #print('{0} {1} is collaborated on the file'.format(target.type.capitalize(), target.login))
                    if target.login.lower() == email.lower():
                        print(f"{folder.name} Removing collaboration with {email}")
                        collab.delete()

if __name__ == '__main__':
    main()
