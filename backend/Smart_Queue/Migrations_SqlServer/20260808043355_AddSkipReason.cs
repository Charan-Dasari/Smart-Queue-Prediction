using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Smart_Queue.Migrations
{
    /// <inheritdoc />
    public partial class AddSkipReason : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "SkipReason",
                table: "QueueTokens",
                type: "nvarchar(200)",
                maxLength: 200,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SkipReason",
                table: "Appointments",
                type: "nvarchar(200)",
                maxLength: 200,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "SkipReason",
                table: "QueueTokens");

            migrationBuilder.DropColumn(
                name: "SkipReason",
                table: "Appointments");
        }
    }
}
