#!/usr/bin/env python3
"""
Disclaimer: AI generated code

test_uart.py — Send a message over UART and echo any responses.

Usage:
    python3 test_uart.py ["your message here"]
    python3 test_uart.py "hello" --port /dev/ttyAMA0 --baud 9600 --timeout 2

Raspberry Pi 5 notes:
    - Default UART port: /dev/ttyAMA0 (maps to UART0 on GPIO 14/15)
    - Disable serial console and enable UART hardware (if needed): sudo raspi-config → Interface Options → Serial Port
    - Install pyserial if not present: pip install pyserial
"""

import sys
import time
import argparse
import serial


def parse_args():
    parser = argparse.ArgumentParser(
        description="Send a message over UART and echo any responses."
    )
    parser.add_argument(
        "message",
        nargs='?',
        default="Hello World",
        help="The message/argument to send over UART."
    )
    parser.add_argument(
        "--port", "-p",
        default="/dev/ttyAMA0",
        help="Serial port to use (default: /dev/ttyAMA0)"
    )
    parser.add_argument(
        "--baud", "-b",
        type=int,
        default=115200,
        help="Baud rate (default: 115200)"
    )
    parser.add_argument(
        "--timeout", "-t",
        type=float,
        default=2.0,
        help="Read timeout in seconds (default: 2.0)"
    )
    parser.add_argument(
        "--newline", "-n",
        action="store_true",
        default=True,
        help="Append \\r\\n to the message (default: True)"
    )
    parser.add_argument(
        "--no-newline",
        dest="newline",
        action="store_false",
        help="Do not append a newline to the message"
    )
    return parser.parse_args()


def main():
    args = parse_args()

    # Build the bytes to send
    message = args.message
    if args.newline:
        message += "\r\n"
    payload = message.encode("utf-8")

    print(f"[UART] Port    : {args.port}")
    print(f"[UART] Baud    : {args.baud}")
    print(f"[UART] Timeout : {args.timeout}s")
    print(f"[UART] Sending : {repr(payload)}")
    print("-" * 40)

    try:
        with serial.Serial(
            port=args.port,
            baudrate=args.baud,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            timeout=args.timeout,
        ) as ser:
            # Flush any stale data
            ser.reset_input_buffer()
            ser.reset_output_buffer()

            # Send the message
            bytes_written = ser.write(payload)
            ser.flush()
            print(f"[TX] Sent {bytes_written} byte(s).")

            # Echo loop — read until timeout produces no more data
            print("[RX] Waiting for response...")
            start = time.monotonic()
            received = bytearray()

            while True:
                chunk = ser.read(ser.in_waiting or 1)
                if chunk:
                    received.extend(chunk)
                    # Print each chunk as it arrives
                    try:
                        text = chunk.decode("utf-8", errors="replace")
                    except Exception:
                        text = repr(chunk)
                    print(f"[RX] {repr(text)}", flush=True)
                else:
                    # No data — check if we've exceeded the timeout
                    elapsed = time.monotonic() - start
                    if elapsed >= args.timeout:
                        break

            if received:
                print("-" * 40)
                print(f"[RX] Total received : {len(received)} byte(s)")
                try:
                    print(f"[RX] Full response  : {received.decode('utf-8', errors='replace')!r}")
                except Exception:
                    print(f"[RX] Raw bytes      : {received!r}")
            else:
                print("[RX] No response received within timeout.")

    except serial.SerialException as e:
        print(f"[ERROR] Could not open serial port '{args.port}': {e}", file=sys.stderr)
        print(
            "\nTroubleshooting tips:\n"
            "  1. Disable serial console and enable UART hardware: sudo raspi-config → Interface Options → Serial Port\n"
            "  2. Check permissions: sudo usermod -aG dialout $USER  (then log out/in)\n"
            "  3. Check port name: ls /dev/ttyAMA* /dev/ttyS*\n"
            "  4. Install pyserial: pip install pyserial --break",
            file=sys.stderr,
        )
        sys.exit(1)
    except KeyboardInterrupt:
        print("\n[INFO] Interrupted by user.")
        sys.exit(0)


if __name__ == "__main__":
    main()
