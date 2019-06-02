import asyncio
import aiohttp
import json
import re
from time import time
import logging
import sys

#Constants for access to client tuple
RECEIVER = 0
TIME_DIFF = 1
LATITUDE = 2
LONGITUDE = 3
TIME_SENT = 4

#String literals
HOST = "127.0.0.1"
GOLOMAN = "Goloman"
HANDS = "Hands"
HOLIDAY = "Holiday"
WILKES = "Wilkes"
WELSH = "Welsh"
CURRENT_SERVER = None

#Port numbers and communication links
SERVER_PORTS = {GOLOMAN: 11958, HANDS: 11959, HOLIDAY: 11960, WILKES: 11961, WELSH: 11962}
SERVER_LINKS = {GOLOMAN: [HANDS, HOLIDAY, WILKES], HANDS: [GOLOMAN, WILKES], HOLIDAY: [GOLOMAN, WILKES, WELSH], WILKES: [GOLOMAN, HANDS, HOLIDAY], WELSH: [HOLIDAY]}
CLIENTS_LOCATION_DB = {}

#API Details
API_ENDPOINT = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=-33.8670522,151.1957362&radius=1500"
API_KEY = "&key=AIzaSyAdP1UsAdTwQx55UxAM_oR-VWmh5GyTMpU" #FIXME: WRONG KEY FIX KEY


async def main():
    #Check if called with correct arguments
    if (len(sys.argv) != 2):
        print("Usage: server.py [server name]")
        exit(code=1)

    elif (not (sys.argv[1] in SERVER_PORTS)):
        print("Invalid server \n. Please choose a server from one of the following: Goloman, Hands, Holiday, Wilkes, Welsh")
        exit(code=1)
    #If so then start 
    else:
        global CURRENT_SERVER
        CURRENT_SERVER = sys.argv[1]
        print("Starting " + CURRENT_SERVER)
        server = await asyncio.start_server(handle_connection, host=HOST, port=SERVER_PORTS[CURRENT_SERVER])
        try:
            await server.serve_forever()
        except KeyboardInterrupt:
            print("Keyboard interrupt")
        finally:
            await server.close()
        exit(code=0)

async def flood(message):
    for server in SERVER_LINKS[CURRENT_SERVER]:
        try:
            reader, writer = await asyncio.open_connection(HOST, SERVER_PORTS[server])
            writer.write(message.encode())
            await writer.drain()
            writer.close()
            print("Successfully send message to " + server)
        except:
           print("Couldn't send message to " + server)

async def handle_connection(reader, writer):
    
    data = await reader.readline()
    message = data.decode().split()

    if (message[0] == "IAMAT"):
        # Store client location
        try:
            client_id = message[1]
            latitude = message[2].split("-")[0]
            longitude = message[2].split("-")[1]
            time_sent = message[3]
            print("Received message: " + data.decode())
        except:
            print("Invalid command")

        time_diff = time() - float(time_sent)
        CLIENTS_LOCATION_DB[client_id] = (CURRENT_SERVER, time_diff, latitude, longitude, time_sent)
        
        # Reply to client with AT message
        reply = "AT " + str(time_diff) + " " + CURRENT_SERVER + " " + client_id + " " + latitude + "-" + longitude + " " + time_sent + "\n"
        writer.write(reply.encode())
        await writer.drain()
        writer.close()

        #Flood message
        await flood(reply)

    elif (message[0] == "WHATSAT"):
        #check if client in database
        client_id = message[1]
        if (client_id not in CLIENTS_LOCATION_DB):
            print("Client not in db")
            return
        client_record = CLIENTS_LOCATION_DB[client_id]
        reply = "AT " + str(client_record[TIME_DIFF]) + " " + client_record[RECEIVER] + " " + client_id + " " + client_record[LATITUDE] + "-" + client_record[LONGITUDE] + " " + client_record[TIME_SENT] + "\n"        
        writer.write(reply.encode())

        #Make call to Places API
        async with aiohttp.ClientSession() as session:
            async with session.get(API_ENDPOINT) as resp:
                json_response = await resp.text()
                writer.write(json_response.encode())

        #Cleanup
        await writer.drain()
        writer.close()

    elif (message[0] == "AT"):
        try:
            time_diff = message[1]
            receiver = message[2]
            client_id = message[3]
            latitude = message[4].split("-")[0]
            longitude = message[4].split("-")[1]
            time_sent = message[5]
        except:
            print("Invalid command")
        
        #Update information in db and flood if new info
        if ((client_id not in CLIENTS_LOCATION_DB) or (time_sent > CLIENTS_LOCATION_DB[client_id][TIME_SENT])):
            CLIENTS_LOCATION_DB[client_id] = (receiver, time_diff, latitude, longitude, time_sent)
            await flood(data.decode())
        else:
            print("Not forwarding")

    else:
        print("Invalid message")
    
    return
    

if __name__ == '__main__':
    asyncio.run(main())