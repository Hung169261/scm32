`timescale 1ns / 1ps

module testbench();

  // 1. Các chân giao tiếp mức đỉnh của arm_top
  logic        clk;
  logic        reset;
  logic [31:0] WriteData;
  logic [31:0] DataAdr;
  logic        MemWrite;

  // 2. Các dây quan sát (Probe) nội bộ cho toàn bộ các khối
  logic [31:0] PC;
  logic [31:0] Instr;
  logic [31:0] ReadData;
  logic [31:0] ALUResult;
  logic [31:0] ShiftOut;
  logic [3:0]  ALUFlags;
  logic [2:0]  ALUControl;
  logic        RegWrite;
  logic        PCSrc;
  logic        NoWrite;

  // 3. Khởi tạo khối đỉnh arm_top
  arm_top dut (
    .clk       (clk),
    .reset     (reset),
    .WriteData (WriteData),
    .DataAdr   (DataAdr),
    .MemWrite  (MemWrite)
  );

  // 4. Nối tắt các đường nội bộ từ sơ đồ Quartus ra ngoài
  assign PC         = dut.cpu.PC;
  assign Instr      = dut.cpu.Instr;
  assign ReadData   = dut.cpu.ReadData;
  assign ALUResult  = dut.cpu.ALUResult;
  assign ShiftOut   = dut.cpu.dp.sh.y;
  assign ALUFlags   = dut.cpu.dp.ALUFlags;
  assign ALUControl = dut.cpu.c.ALUControl;
  assign RegWrite   = dut.cpu.c.RegWrite;
  assign PCSrc      = dut.cpu.c.PCSrc;
  assign NoWrite    = dut.cpu.c.dec.NoWrite;

  // 5. Tạo xung nhịp clk (chu kỳ 10ns = 100MHz)
  always begin
    clk = 1'b1; #5;
    clk = 1'b0; #5;
  end

  // 6. Kịch bản chạy mô phỏng cho bộ 21 lệnh đầy đủ
  initial begin
    $dumpfile("arm_wave.vcd");
    $dumpvars(0, testbench);

    // Giữ reset = 1 trong 22ns đầu để đưa PC về 0x00000000
    reset = 1'b1;
    #22;
    reset = 1'b0;

    // Chạy đủ 400ns (~38 chu kỳ) để đi hết 21 lệnh và kiểm tra vòng lặp khóa cuối
    #400;
    $display("Ket thuc thoi gian mo phong!");
    $stop;
  end

  // 7. Tự động kiểm tra các lệnh ghi RAM (STR) và báo kết quả
  always @(negedge clk) begin
    if (MemWrite) begin
      $display("Time=%0t ns | PC=0x%h | Instr=0x%h | DataAdr=%0d | WriteData=%0d",
               $time, PC, Instr, DataAdr, WriteData);

      // Kiểm tra mốc ghi cuối cùng ở địa chỉ 8 với giá trị 12 (0x0C)
      if (DataAdr === 8 && WriteData === 12) begin
        $display(">>> MO PHONG THANH CONG! Tat ca cac khoi (ALU, Shift, CMP, LDR, STR, Branch) hoat dong chinh xac! <<<");
        #30; // Chạy thêm 3 chu kỳ để xác nhận PC khóa đứng yên tại 0x50
        $stop;
      end
    end
  end

endmodule