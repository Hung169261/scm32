`timescale 1ns / 1ps

module testbench();

  // 1. Khai báo các tín hiệu nối với cổng của arm_top
  logic        clk;
  logic        reset;
  logic [31:0] WriteData;
  logic [31:0] DataAdr;
  logic        MemWrite;

  // 2. Khai báo thêm các dây quan sát (Probe) để hiện sẵn trên cửa sổ Wave
  logic [31:0] PC;
  logic [31:0] Instr;
  logic [31:0] ReadData;
  logic [31:0] ALUResult;
  logic [3:0]  ALUFlags;
  logic        RegWrite;
  logic        PCSrc;
  logic [1:0]  ALUControl;

  // 3. Khởi tạo khối đỉnh arm_top (tên instance: dut)
  arm_top dut (
    .clk       (clk),
    .reset     (reset),
    .WriteData (WriteData),
    .DataAdr   (DataAdr),
    .MemWrite  (MemWrite)
  );

  // 4. Nối tắt (Hierarchical tap) các đường nội bộ bên trong sơ đồ ra ngoài để dễ nhìn sóng
  assign PC         = dut.cpu.PC;
  assign Instr      = dut.cpu.Instr;
  assign ReadData   = dut.cpu.ReadData;
  assign ALUResult  = dut.cpu.ALUResult;
  assign ALUFlags   = dut.cpu.dp.ALUFlags;
  assign RegWrite   = dut.cpu.c.RegWrite;
  assign PCSrc      = dut.cpu.c.PCSrc;
  assign ALUControl = dut.cpu.c.ALUControl;

  // 5. Tạo xung nhịp clk (chu kỳ 10ns = 100MHz)
  always begin
    clk = 1'b1; #5;
    clk = 1'b0; #5;
  end

  // 6. Kịch bản chạy mô phỏng
  initial begin
    // Xuất toàn bộ sóng của mọi khối con (phục vụ GTKWave / Vivado / ModelSim)
    $dumpfile("arm_wave.vcd");
    $dumpvars(0, testbench);

    // Giữ reset ở mức 1 trong 22ns đầu để khởi tạo PC = 0
    reset = 1'b1;
    #22;
    reset = 1'b0;

    // Chạy mô phỏng tối đa 300ns (30 chu kỳ lệnh) nếu chưa gặp điều kiện dừng
    #300;
    $display("Hoan thanh thoi gian mo phong!");
    $stop;
  end

  // 7. Tự động kiểm tra và in log mỗi khi có lệnh ghi bộ nhớ (MemWrite = 1)
  always @(negedge clk) begin
    if (MemWrite) begin
      $display("Time=%0t | PC=%h | Instr=%h | DataAdr=%0d (0x%h) | WriteData=%0d (0x%h)",
               $time, PC, Instr, DataAdr, DataAdr, WriteData, WriteData);
      
      // Nếu chạy bài test chuẩn ghi giá trị 7 vào địa chỉ 84 thì báo thành công
      if (DataAdr === 84 && WriteData === 7) begin
        $display(">>> MO PHONG THANH CONG! Da ghi dung gia tri 7 vao dia chi 84 <<<");
        #20;
        $stop;
      end
    end
  end

endmodule