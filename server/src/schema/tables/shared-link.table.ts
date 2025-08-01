import { SharedLinkType } from 'src/enum';
import { AlbumTable } from 'src/schema/tables/album.table';
import { UserTable } from 'src/schema/tables/user.table';
import {
  Column,
  CreateDateColumn,
  ForeignKeyColumn,
  Generated,
  PrimaryGeneratedColumn,
  Table,
  Timestamp,
  Unique,
} from 'src/sql-tools';

@Table('shared_links')
@Unique({ name: 'UQ_sharedlink_key', columns: ['key'] })
export class SharedLinkTable {
  @PrimaryGeneratedColumn()
  id!: Generated<string>;

  @Column({ type: 'character varying', nullable: true })
  description!: string | null;

  @ForeignKeyColumn(() => UserTable, { onDelete: 'CASCADE', onUpdate: 'CASCADE' })
  userId!: string;

  @Column({ type: 'bytea', indexName: 'IDX_sharedlink_key' })
  key!: Buffer; // use to access the individual asset

  @Column()
  type!: SharedLinkType;

  @CreateDateColumn()
  createdAt!: Generated<Timestamp>;

  @Column({ type: 'timestamp with time zone', nullable: true })
  expiresAt!: Timestamp | null;

  @Column({ type: 'boolean', default: false })
  allowUpload!: boolean;

  @ForeignKeyColumn(() => AlbumTable, {
    nullable: true,
    onDelete: 'CASCADE',
    onUpdate: 'CASCADE',
    indexName: 'IDX_sharedlink_albumId',
  })
  albumId!: string | null;

  @Column({ type: 'boolean', default: true })
  allowDownload!: Generated<boolean>;

  @Column({ type: 'boolean', default: true })
  showExif!: Generated<boolean>;

  @Column({ type: 'character varying', nullable: true })
  password!: string | null;
}
