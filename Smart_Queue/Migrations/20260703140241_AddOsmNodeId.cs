using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Smart_Queue.Migrations
{
    /// <inheritdoc />
    public partial class AddOsmNodeId : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<long>(
                name: "OsmNodeId",
                table: "ServiceProviders",
                type: "bigint",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "OsmNodeId",
                table: "ServiceProviders");
        }
    }
}
