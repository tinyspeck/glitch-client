package org.igorcosta.hacks
{
    import flash.display.LoaderInfo;
    import flash.utils.ByteArray;
    import flash.utils.Endian;

   /**
  * Direct reading of SWF file
  * Distributed under the new BSD License
  * @author Paul Sivtsov - ad@ad.by
  */

	public class SWF
	{
    ///////////////////////////////////////////////////////////////////////////
    // Returns compilation date of current module
    public static function readCompilationDate(serialNumber: ByteArray = null): Date
    {
      const compilationDate: Date = new Date;
      const DATETIME_OFFSET: uint = 18;

      /* example of filled SWF_SERIALNUMBER structure
      struct SWF_SERIALNUMBER
      {
        UI32 Id;         // "3"
        UI32 Edition;    // "6"
                         // "flex_sdk_4.0.0.3342"
        UI8 Major;       // "4."
        UI8 Minor;       // "0."
        UI32 BuildL;     // "0."
        UI32 BuildH;     // "3342"
        UI32 TimestampL;
        UI32 TimestampH;
      };
      */

      // the SWF_SERIALNUMBER structure exists in FLEX swfs only, not FLASH
      if (serialNumber == null)
        return null;

      // date stored as uint64
      serialNumber.position = DATETIME_OFFSET;
      serialNumber.endian = Endian.LITTLE_ENDIAN;
      compilationDate.time = serialNumber.readUnsignedInt() + serialNumber.readUnsignedInt() * (uint.MAX_VALUE + 1);

      return compilationDate;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Returns contents of Adobe SerialNumber SWF tag
    public static function readSerialNumber(src:ByteArray): ByteArray
    {
      const TAG_SERIAL_NUMBER: uint = 0x29;
      return findAndReadTagBody(src, TAG_SERIAL_NUMBER);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Returns the tag body if it is possible
    public static function findAndReadTagBody(src:ByteArray, theTagCode: uint): ByteArray
    {
      /*
      SWF File Header
      Field      Type  Offset   Comment
      -----      ----  ------   -------
      Signature  UI8   0        Signature byte: “F” indicates uncompressed, “C” indicates compressed (SWF 6 and later only)
      Signature  UI8   1        Signature byte always “W”
      Signature  UI8   2        Signature byte always “S”
      Version    UI8   3        Single byte file version (for example, 0x06 for SWF 6)
      FileLength UI32  4        Length of entire file in bytes
      FrameSize  RECT  8        Frame size in twips
      FrameRate  UI16  8+RECT   Frame delay in 8.8 fixed number of frames per second
      FrameCount UI16  10+RECT  Total number of frames in file
      */

      // skip AVM2 SWF header
      // skip Signature, Version & FileLength
      src.position = 8;
      // skip FrameSize
      const RECT_UB_LENGTH: uint = 5;
      const RECT_SB_LENGTH: uint = src.readUnsignedByte() >> (8 - RECT_UB_LENGTH);
      const RECT_LENGTH: uint = Math.ceil((RECT_UB_LENGTH + RECT_SB_LENGTH * 4) / 8);
      src.position += (RECT_LENGTH - 1);
      // skip FrameRate & FrameCount
      src.position += 4;

      while (src.bytesAvailable > 0)
        with (readTag(src, theTagCode))
      {
        if (tagCode == theTagCode)
          return tagBody;
      }

      return null;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Returns tag from current read position
    private static function readTag(src: ByteArray, theTagCode: uint): Object
    {
      src.endian = Endian.LITTLE_ENDIAN;

      const tagCodeAndLength: uint = src.readUnsignedShort();
      const tagCode: uint = tagCodeAndLength >> 6;
      const tagLength: uint = function(): uint {
        const MAX_SHORT_TAG_LENGTH: uint = 0x3F;
        const shortLength: uint = tagCodeAndLength & MAX_SHORT_TAG_LENGTH;
        return (shortLength == MAX_SHORT_TAG_LENGTH) ? src.readUnsignedInt() : shortLength;
      }();

      const tagBody: ByteArray = new ByteArray;
      if (tagLength > 0)
        src.readBytes(tagBody, 0, tagLength);

      return {
        tagCode: tagCode,
        tagBody: tagBody
      };
    }
  }
}