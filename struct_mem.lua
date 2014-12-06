-- // LN-200 Mapping Fdisk File Format

--[[Meanings of C_mapping_summary_msg_t status_type values:
	Normal      = 0x01,
	RunEntry    = 0x02,
	Error       = 0x03,
	RunStart    = 0x04,
	RunEnd      = 0x05,
	FDISKError  = 0x06,
	FullDisk    = 0x07,
	Verify      = 0x08,
	Retry       = 0x09,
	TickleStart = 0x0A,
	TickleEnd   = 0x0B,
	SPIError    = 0x0C,
	StartTime   = 0x0D,
	StopTime    = 0x0E,
	Blank       = 0xFF,
--]]


ffi = require("ffi") 
ffi.cdef[[
#pragma pack(1)

typedef struct uint24 {
	unsigned int data : 24;
} C_uint24;

typedef struct mapping_header_t {
	unsigned short abcd[256]; // Filled with 0xABCD little endian
} C_mapping_header_t;
 
typedef struct gps_time_t {
	unsigned short type;
	double latitude;
	double longitude;
	double altitude;
	unsigned int sow; // second of week
	unsigned short week;
	unsigned short leap;
	unsigned short year;
	unsigned short month;
	unsigned short day;
	unsigned short hour;
	unsigned short minute;
	unsigned short second;
	unsigned short time_precision;
	unsigned short fix_type;
	unsigned short quality;
	unsigned char junk[12];
} C_gps_time_t;
 
typedef struct mapping_summary_msg_t {
	unsigned char status_type; // see above for meanings
	unsigned char summary_header; // should be 0xAC
	unsigned long baseline;
	unsigned long next_empty_sector;
	unsigned long odo_a;
	unsigned long odo_b;
	unsigned long num_missed_sectors;
	unsigned short sensor_status;
	unsigned short temperature;
	unsigned short battery_voltage;
	unsigned long other;	
	C_gps_time_t gps_time;
	unsigned char junk[416];
} C_mapping_summary_msg_t;

typedef struct imu_line_t
{
   unsigned short packetHeader;      //byte 0-1
   unsigned char Address;                     //2
   unsigned char Control;                     //3
   C_uint24 gyro_x_increment;         //13-15
   C_uint24 gyro_y_increment;         //16-18
   C_uint24 gyro_z_increment;         //19-21
   C_uint24 accel_x_increment;        //4-6
   C_uint24 accel_y_increment;        //7-9
   C_uint24 accel_z_increment;        //10-12
   unsigned long imu_status;         //22-25       //0000 0000
   unsigned short crc;               //26-27
   unsigned short stop;              //28-29       //ff7e
   unsigned short packetFooter;      //30-31       //a521
   unsigned short odo0;              //32-33
   unsigned short timestamp;         //34-35
   unsigned short odo1;              //36-37
   unsigned short junk2;             //38-39 
} C_imu_line_t;
 
typedef struct mapping_raw_data_t {
	unsigned short TEMPERATURE;
	unsigned short VOLTAGE;
	unsigned long  ODO_A_32;
	unsigned long  ODO_B_32;
	unsigned short junk[12];
	unsigned long baseline_header;
	C_imu_line_t imu_line[400];		
} C_mapping_raw_data_t;
]]

-- typedef struct mapping_fdisk {
-- 	C_mapping_header_t mapping_header;
-- 	C_mapping_summary_msg_t mapping_summary_msg[4096];
-- 	C_mapping_raw_data_t mapping_raw_data[];
-- } C_mapping_fdisk;
