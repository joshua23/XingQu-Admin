import React from 'react'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/Table"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/Card"
import { Badge } from "@/components/ui/Badge"
import { cn } from "@/lib/utils"

export interface TableColumn {
  key: string;
  label: string;
  width?: string;
  align?: 'left' | 'center' | 'right';
  render?: (value: any, row: any) => React.ReactNode;
}

interface DataTableProps {
  title: string;
  columns: TableColumn[];
  data: any[];
  className?: string;
}

export function DataTable({ title, columns, data, className }: DataTableProps) {
  const renderCell = (column: TableColumn, row: any) => {
    const value = row[column.key];

    if (column.render) {
      return column.render(value, row);
    }

    return value;
  };

  return (
    <Card className={cn("", className)}>
      <CardHeader>
        <CardTitle className="text-lg font-semibold">{title}</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                {columns.map((column) => (
                  <TableHead
                    key={column.key}
                    className={cn(
                      "font-medium",
                      column.align === 'center' && "text-center",
                      column.align === 'right' && "text-right"
                    )}
                    style={{ width: column.width }}
                  >
                    {column.label}
                  </TableHead>
                ))}
              </TableRow>
            </TableHeader>
            <TableBody>
              {data.length === 0 ? (
                <TableRow>
                  <TableCell
                    colSpan={columns.length}
                    className="text-center text-muted-foreground py-8"
                  >
                    暂无数据
                  </TableCell>
                </TableRow>
              ) : (
                data.map((row, index) => (
                  <TableRow key={index} className="hover:bg-muted/50">
                    {columns.map((column) => (
                      <TableCell
                        key={column.key}
                        className={cn(
                          column.align === 'center' && "text-center",
                          column.align === 'right' && "text-right"
                        )}
                      >
                        {renderCell(column, row)}
                      </TableCell>
                    ))}
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </div>
      </CardContent>
    </Card>
  );
}

// Utility components for common table cell types
export const StatusBadge = ({ status }: { status: string }) => {
  const getVariant = () => {
    switch (status) {
      case '正常': return 'default';
      case '冻结': return 'destructive';
      case '注销': return 'secondary';
      default: return 'default';
    }
  };

  return <Badge variant={getVariant()}>{status}</Badge>;
};

export const PercentageCell = ({ value }: { value: number }) => {
  const color = value > 0 ? 'text-metric-positive' : value < 0 ? 'text-metric-negative' : 'text-metric-neutral';
  return <span className={color}>{value}%</span>;
};
