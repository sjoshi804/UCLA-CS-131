import asyncio

HOST = "127.0.0.1"
GOLOMAN = "Goloman"
HANDS = "Hands"
HOLIDAY = "Holiday"
WILKES = "Wilkes"
WELSH = "Welsh"
SERVER_PORTS = {GOLOMAN: 11958, HANDS: 11959, HOLIDAY: 11960, WILKES: 11961, WELSH: 11962}
async def main():
    reader, writer = await asyncio.open_connection(HOST, 12345)
    writer.write("John\n".encode())
    data = await reader.readline()
    print('Received: {}'.format(data.decode()))
    writer.close()

if __name__ == '__main__':
    asyncio.run(main())